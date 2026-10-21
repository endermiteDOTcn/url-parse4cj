'use strict';

const fs = require('node:fs');
const path = require('node:path');
const vm = require('node:vm');
const assert = require('node:assert/strict');
const { execFileSync, spawnSync } = require('node:child_process');
const root = path.resolve(__dirname, '..');
const qs = require('../upstream/querystringify');
const required = require('../upstream/requires-port');
const upstreamPath = path.join(root, 'upstream/url-parse/index.js');
const moduleObject = { exports: {} };
vm.runInNewContext(fs.readFileSync(upstreamPath, 'utf8'), {
  module: moduleObject, exports: moduleObject.exports,
  require: name => ({ 'querystringify': qs, 'requires-port': required })[name],
}, { filename: upstreamPath });
const Upstream = moduleObject.exports;
const fields = ['auth', 'hash', 'host', 'hostname', 'href', 'origin', 'password',
  'pathname', 'port', 'protocol', 'slashes', 'username'];
const baseFields = ['protocol', 'host', 'hostname', 'port', 'pathname', 'href'];
const hex = value => Buffer.from(String(value ?? ''), 'utf8').toString('hex') || '-';
const wire = values => values.map(hex).join('|');
const baseWire = value => baseFields.map(key => hex(value[key])).concat(
  value.slashes === undefined ? '-' : value.slashes ? '1' : '0').join(',');
const objectWire = value => Object.keys(value).map(key => `${hex(key)}:${value[key] === undefined ? 'U' : hex(value[key])}`).join(',') || '-';
const snapshot = (url, stringify) => wire(fields.map(key => String(url[key])).concat(
  typeof url.query === 'string' ? 'S:' + url.query : 'O:' + qs.stringify(url.query),
  Upstream.prototype.toString.call(url, stringify)));
const cases = [];
let suite = '';
let upstreamTests = 0;

function startCommand(args) {
  let [address = '', base, parser] = args;
  if (typeof base !== 'string' && typeof base !== 'object') { parser = base; base = undefined; }
  const baseType = typeof base === 'string' ? 'S' : base && typeof base === 'object' ? 'O' : 'N';
  const baseValue = baseType === 'S' ? hex(base) : baseType === 'O' ? baseWire(base) : '-';
  return ['N', hex(address), baseType, baseValue,
    typeof parser === 'function' ? 'C' : parser ? '1' : '0', typeof parser === 'function' ? hex(parser('')) : '-'].join('|');
}

function operation(args, direct = false) {
  const [key, value, flag] = args;
  const type = value && typeof value === 'object' ? 'O' : typeof value === 'boolean' ? 'B' : typeof value === 'number' ? 'I' : 'S';
  const encoded = type === 'O' ? objectWire(value) : type === 'B' ? value ? '1' : '0' : hex(value);
  return [direct ? 'D' : 'S', hex(key), type, encoded, flag === true ? '1' : '0',
    typeof flag === 'function' ? hex(flag(value)) : '-'].join('|');
}

function record(commands, expected, description) { cases.push({ commands: [...commands], expected, description }); }

function Spy(...args) {
  const initial = startCommand(args);
  let target;
  try { target = new Upstream(...args); }
  catch (error) { record([initial, 'O|-'], 'E', suite); throw error; }
  const commands = [initial];
  if (suite) record([...commands, 'O|-'], snapshot(target), suite + ': parse');
  const proxy = new Proxy(target, {
    get(object, key) {
      if (key === 'set') return (...values) => {
        // TypeScript accepts a boolean or a query-parser callback as the third argument.
        if (values[2] && typeof values[2] !== 'boolean' && typeof values[2] !== 'function') {
          return Upstream.prototype.set.apply(object, values);
        }
        commands.push(operation(values));
        try { Upstream.prototype.set.apply(object, values); }
        catch (error) { if (suite) record([...commands, 'O|-'], 'E', suite + ': set exception'); throw error; }
        if (suite) record([...commands, 'O|-'], snapshot(object), suite + ': set ' + values[0]);
        return proxy;
      };
      if (key === 'toString') return stringify => {
        if (suite) record([...commands, 'O|' + (typeof stringify === 'function' ? hex(stringify(object.query)) : '-')],
          snapshot(object, stringify), suite + ': toString');
        return Upstream.prototype.toString.call(object, stringify);
      };
      return object[key];
    },
    set(object, key, value) { object[key] = value; commands.push(operation([key, value], true)); return true; },
  });
  return proxy;
}
Spy.qs = qs;
Spy.location = Upstream.location;
Spy.trimLeft = value => {
  const result = Upstream.trimLeft(value);
  if (suite) record(['T|' + hex(value ? String(value) : '')], wire([result]), suite);
  return result;
};
Spy.extractProtocol = (text, base = {}) => {
  const result = Upstream.extractProtocol(text, base);
  if (suite) record(['X|' + hex(text) + '|' + baseWire(base)],
    wire([result.protocol, result.slashes, result.slashesCount, result.rest]), suite);
  return result;
};

// Execute the original test bodies with their fluent assertions backed by node:assert.
function assume(value) {
  let chain;
  const actions = {
    equal: expected => assert.equal(value, expected),
    equals: expected => assert.equal(value, expected),
    eql: expected => assert.deepEqual(JSON.parse(JSON.stringify(value)), JSON.parse(JSON.stringify(expected))),
    a: expected => assert.equal(typeof value, expected),
    an: expected => assert.equal(typeof value, expected),
    true: () => assert.equal(value, true), false: () => assert.equal(value, false),
    empty: () => assert.equal(Object.keys(value).length, 0),
    throws: error => assert.throws(value, error === Error ? undefined : error),
  };
  chain = new Proxy(() => chain, { get: (_, key) => actions[key] ? (...args) => { actions[key](...args); return chain; } : chain });
  return chain;
}
let randomState = 20261021;
function random() { randomState = (Math.imul(randomState, 1664525) + 1013904223) >>> 0; return randomState / 2 ** 32; }
const seededMath = Object.create(Math);
seededMath.random = random;
const sandbox = { console, Error, Math: seededMath, describe: (_, body) => body(), it: (name, body) => {
  suite = name; body(); upstreamTests++; suite = '';
} };
sandbox.global = sandbox;
sandbox.require = name => {
  if (name === 'assume') return assume;
  if (name === '../') return Spy;
  if (name === 'querystringify') return qs;
  if (name === './fuzzy') {
    const m = { exports: {} };
    vm.runInNewContext(fs.readFileSync(path.join(root, 'upstream/url-parse/test/fuzzy.js'), 'utf8'),
      { module: m, exports: m.exports, require: () => Spy, Math: seededMath });
    return m.exports;
  }
  throw new Error('Unexpected upstream test dependency ' + name);
};
vm.runInNewContext(fs.readFileSync(path.join(root, 'upstream/url-parse/test/test.js'), 'utf8'), sandbox,
  { filename: 'upstream/url-parse/test/test.js' });

function addParse(address, base, parseQuery = false) {
  const args = base === undefined ? [address, parseQuery] : [address, base, parseQuery];
  const command = startCommand(args);
  try { record([command, 'O|-'], snapshot(new Upstream(...args)), 'generated parse ' + JSON.stringify(args)); }
  catch (_) { record([command, 'O|-'], 'E', 'generated parse exception ' + JSON.stringify(args)); }
}

const addresses = ['', '/', '//', '///', 'foo', '.', '..', '../c', '../../x', './', '?', '#',
  '?a=b+c&a=second&2=b&1=a', '?__proto__=x&constructor=x&toString=x&good=1',
  '?bad=%FF&good=%E4%B8%AD', '?empty=&bare&=value', '?a?b=c#d',
  'http://EXAMPLE.com:80/a', 'https://user:p%40ss@EXAMPLE.com:443/a?q=1#b',
  'http://[::1]:80/a', 'http://[::1]:8080/a', 'http://example.com:', 'http://example.com::',
  'http://example.com:8080:', 'http://@/127.0.0.1', 'file:///C:/a', 'file://host/path',
  'file:C:\\a\\b', 'mailto:alice@example.com', 'foo:////host/path', 'javascript:alert(1)',
  'http://u%ZZ:p@example.com', 'http://%ED%A0%80@example.com', 'http://u%F0%9F%98%80:p@example.com',
  'http://host:80\u2028', 'http://host:80\u2029', 'http://host:\u2028',
  'HTTP://İΣΟΣ.例子/A', 'http:\\\\Example.com\\a?x=\\b#c\\d'];
const bases = [undefined, '', 'http://u:p@base.example:808/a/b?old=1#old', 'https://base.example/a/b/',
  'file:///C:/a/b', 'foo://base.example/a/b', { protocol: 'https:', host: 'base.example',
    hostname: 'base.example', pathname: '/a/b', href: 'https://base.example/a/b' },
  { protocol: 'blob:', pathname: 'https%3A//base.example/a/b' },
  { protocol: 'HTTP:', host: 'BASE.EXAMPLE', hostname: 'BASE.EXAMPLE', pathname: '/a', slashes: true }];
for (const address of addresses) for (const base of bases) for (const mode of [false, true]) addParse(address, base, mode);
for (const protocol of ['http:', 'https:', 'ftp:', 'ws:', 'wss:', 'file:', 'gopher:', 'foo:', '']) {
  for (const slash of ['', '/', '//', '///', '\\', '\\\\', '/\\', '\\/']) {
    for (const suffix of ['Example.com/a?x=1#h', 'u:p@host:80/a', '/C:/file']) {
      addParse(protocol + slash + suffix, undefined, false);
      addParse(protocol + slash + suffix, 'https://base/a/b', true);
    }
  }
}
for (let i = 0; i < 500; i++) {
  const pick = values => values[Math.floor(random() * values.length)];
  const address = pick(['http', 'https', 'ws', 'wss', 'ftp', 'gopher', 'foo']) + '://' +
    pick(['', 'a:b@', 'a%40b:c%3Ad@', ':p@']) + pick(['EXAMPLE.com', 'localhost', '[::1]', '127.0.0.1', '例子.测试']) +
    pick(['', ':80', ':443', ':8080', ':21', ':0']) + pick(['', '/', '/a/b', '/a/../b', '/中/😀']) +
    pick(['', '?a=1&b=2', '?a=b+c&a=x', '?2=b&1=a&x=%FF']) + pick(['', '#hash', '#?q=1']);
  addParse(address, undefined, random() > 0.5);
}
for (const query of ['a=b', 'a?b=c', '??a=b', 'a#b=c&c=d', 'a=b=c', '=a=b', 'a&a=2',
  '0=z&01=b&10=c&2=d&4294967295=x', '__proto__=x&valueOf=y&safe=1', '%ZZ=a&ok=b',
  'a=%F0%80%80%80&b=%ED%A0%80&c=%C0%AF&good=%F0%9F%98%80', 'a=+%2B&b=%00']) {
  const result = qs.parse(query);
  record(['Q|' + hex(query)], wire([qs.stringify(result), Object.keys(result).length]), 'query ' + query);
}

function addSequence(address, steps, base, parser = false) {
  const args = base === undefined ? [address, parser] : [address, base, parser];
  const commands = [startCommand(args)];
  const url = new Upstream(...args);
  for (const values of steps) {
    commands.push(operation(values));
    try {
      url.set(...values);
      record([...commands, 'O|-'], snapshot(url), 'set sequence ' + JSON.stringify([address, values]));
    } catch (_) { record([...commands, 'O|-'], 'E', 'set exception ' + JSON.stringify([address, values])); }
  }
}
const mutations = {
  protocol: ['', 'HTTP', 'https:', 'https://', 'file:', 'mailto', 'foo'],
  host: ['', 'EXAMPLE.com', 'EXAMPLE.com:80', '[::1]:8080', 'host:', 'host::', 'host:123:456',
    'host:80\n', 'host:80\r', 'host:80\r\n', 'host:80\u2028', 'host:80\u2029'],
  hostname: ['', 'OTHER.com', '[::1]', 'host:80', 'İΣΟΣ.例子'],
  port: ['', '0', '80', '443', '21', '70', '080', '8080', '-1', 'NaN', 'Infinity'],
  pathname: ['', 'relative', '/absolute', '//double', '../dot', 'a?b#c', '中/😀'],
  hash: ['', 'fragment', '#fragment', '?a=b', '##'],
  auth: ['', 'u:p', 'u:', 'u', ':p', 'u%40:p%3A', 'u@v:p:q', 'u%ZZ:p', 'a:%FF'],
  username: ['', 'User', 'a@b', 'a%40b', '中😀'],
  password: ['', 'p:q@', '%40', '中😀'],
  query: ['', '?a=b', 'a=1&a=2', 'a=%FF&b=ok', '2=b&1=a', { a: 'b c', b: undefined },
    { '10': 'x', '2': 'y', '01': 'z', normal: '中' }],
  href: ['', 'ignored'], origin: ['', 'ignored'], slashes: [true, false],
};
for (const address of ['http://u:p@example.com:808/a?x=1#h', 'https://[::1]/', 'file:///C:/a', 'foo:relative', '']) {
  for (const [key, values] of Object.entries(mutations)) {
    for (const value of values) for (const flag of [false, true]) addSequence(address, [[key, value, flag]]);
  }
  addSequence(address, [['auth', 'a:p'], ['auth', 'b'], ['password', ''], ['protocol', 'https'], ['port', '443']]);
  addSequence(address, [['query', 'a=b', () => '1337'], ['hash', 'next']]);
  addSequence(address, [['protocol', 'foo', () => 'ignored'], ['pathname', 'relative', () => 'ignored'],
    ['hash', 'fragment', () => 'ignored']]);
}
for (const query of [{}, { a: 'b', b: undefined }, Object.fromEntries([['__proto__', 'x'], ['toString', 'y']]),
  { '2': 'b', '1': 'a', '01': 'c', a: '中😀 +&=' }]) {
  for (const prefix of ['', '?', '??', '#', true, false]) {
    record([['F', objectWire(query), typeof prefix === 'boolean' ? 'B' : 'S',
      typeof prefix === 'boolean' ? prefix ? '1' : '0' : hex(prefix)].join('|')],
      wire([qs.stringify(query, prefix)]), 'query stringify ' + JSON.stringify([query, prefix]));
  }
}
for (const address of ['http://host/?a=b', 'http://host/', 'file:///a']) {
  const url = new Upstream(address);
  record([startCommand([address]), 'O|' + hex('replacement')], snapshot(url, () => 'replacement'), 'raw query custom stringify');
}
for (const base of ['http://u:p@EXAMPLE.com:80/a?q=1#h', 'file:///C:/a',
  { protocol: 'blob:', pathname: 'https%3A//host/a/b' },
  { protocol: 'blob:', pathname: 'https%3A//host/%uD83D%uDE00/a' },
  { protocol: 'blob:', pathname: 'https%3A//host/%E4%B8%AD/a' },
  { protocol: 'https:', hostname: 'host', host: 'host', pathname: '/a', href: 'https://host/a' }]) {
  const result = Upstream.location(base);
  record([['L', typeof base === 'string' ? 'S' : 'O', typeof base === 'string' ? hex(base) : baseWire(base)].join('|')],
    wire([result.protocol || '', !!result.slashes, result.host || '', result.hostname || '',
      result.port || '', result.pathname || '', result.href || '']), 'location ' + JSON.stringify(base));
}
const controls = [...Array.from({ length: 33 }, (_, i) => String.fromCodePoint(i)),
  '\u00A0', '\u1680', ...Array.from({ length: 11 }, (_, i) => String.fromCodePoint(0x2000 + i)),
  '\u2028', '\u2029', '\u202F', '\u205F', '\u3000', '\uFEFF', '\u0085'];
for (const control of controls) {
  for (const address of [control + 'http://host/a' + control, 'ht' + control + 'tp://host/a', control]) {
    addParse(address, undefined, true);
    const value = Upstream.extractProtocol(address);
    record(['X|' + hex(address) + '|' + baseWire({})],
      wire([value.protocol, value.slashes, value.slashesCount, value.rest]), 'extract controls');
  }
}
for (let i = 0; i < 1000; i++) {
  const alphabet = ['a', 'b', '0', '1', '2', '+', '%', 'E', '4', 'F', '=', '&', '?', '#', '中', '😀'];
  let text = '';
  for (let n = 0, count = 1 + Math.floor(random() * 35); n < count; n++) text += alphabet[Math.floor(random() * alphabet.length)];
  const query = qs.parse(text);
  record(['Q|' + hex(text)], wire([qs.stringify(query), Object.keys(query).length]), 'query fuzz ' + text);
  const tokens = ['', '.', '..', 'a', 'b', '中', '😀'];
  const relative = Array.from({ length: 1 + Math.floor(random() * 8) }, () => tokens[Math.floor(random() * tokens.length)]).join('/');
  addParse(relative, i % 2 ? 'http://host/a/b/c' : 'http://host/a/b/', i % 3 === 0);
}

const project = path.join(root, 'tests/compatibility');
execFileSync('cjpm', ['build'], { cwd: project, stdio: 'inherit' });
const executable = path.join(project, 'target/release/bin', process.platform === 'win32' ? 'main.exe' : 'main');
const input = cases.map(test => test.commands.join('\n')).join('\n') + '\n';
const result = spawnSync(executable, [], { input, encoding: 'utf8', maxBuffer: 32 * 1024 * 1024 });
if (result.error) throw result.error;
if (result.status !== 0) throw new Error('Compatibility runner failed: ' + result.stderr);
const actual = result.stdout.trimEnd().split(/\r?\n/);
assert.equal(actual.length, cases.length, 'Runner output count');
const mismatches = cases.flatMap((test, index) => actual[index] === test.expected ? [] : [{
  index, ...test, actual: actual[index],
  expectedFields: test.expected.split('|').map(value => value === '-' ? '' : Buffer.from(value, 'hex').toString('utf8')),
  actualFields: actual[index].split('|').map(value => value === '-' ? '' : Buffer.from(value, 'hex').toString('utf8')),
}]);
fs.mkdirSync(path.join(root, 'target'), { recursive: true });
fs.writeFileSync(path.join(root, 'target/compatibility-results.json'), JSON.stringify({
  upstreamTests, comparisons: cases.length, mismatches,
}, null, 2), 'utf8');
if (mismatches.length) {
  console.error(JSON.stringify(mismatches.slice(0, 5), null, 2));
  throw new Error(`${mismatches.length} behavior mismatches; see target/compatibility-results.json`);
}
console.log(`Upstream test bodies: ${upstreamTests} passed`);
console.log(`Behavior comparisons: ${cases.length} passed`);
