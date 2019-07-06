# lua-xmlparser

`xmlparser` is an fast XML parser written entirely in Lua 5.

`xmllpegparser` is an implementation with a visitor and using [`lpeg`](http://www.inf.puc-rio.br/~roberto/lpeg) for even more speed and features.

<!-- summary -->
1. [Installation](#installation)
2. [Test](#test)
3. [xmlparser API](#xmlparser-api)
    1. [Document structure](#document-structure)
    2. [Limitations](#limitations)
4. [xmllpegparser API](#xmllpegparser-api)
    1. [Document structure (default parser)](#document-structure-default-parser)
    2. [Visitor structure](#visitor-structure)
    3. [Default parser limitations](#default-parser-limitations)
5. [Licence](#licence)
<!-- /summary -->


## Installation

```bash
luarocks install --local https://raw.githubusercontent.com/jonathanpoelen/lua-xmlparser/master/xmlparser-2.0-4.rockspec
luarocks install --local https://raw.githubusercontent.com/jonathanpoelen/lua-xmlparser/master/xmllpegparser-2.1-0.rockspec

# or in your local directory lua-xmlparser

luarocks make --local xmlparser-2.0-4.rockspec
luarocks make --local xmllpegparser-2.1-0.rockspec
```

## Test

Run `./example.lua`.

```
./example.lua [xmlfile [enablelpeg [replaceentities]]]`

`enablelpeg` = anything, only to enable xmllpegparser.
`replaceentities` = anything, only to enable replacement of entities.
```

- `./example.lua file.xml '' x`: xmlparser with replacement of entities
- `./example.lua file.xml x`: xmllpegparser


## xmlparser API

- `xmlparser.parse(xmlstring[, subEntities])`: Return a document `table` (see below).
If `subEntities` is `true`, the entities are replaced and a `tentity` member is added to the document `table`.
- `xmlparser.parseFile(filename[, subEntities])`: Return a tuple `document table, error file`.
- `xmlparser.defaultEntitiyTable()`: Return the default entity table (` { quot='"', ... }`).
- `xmlparser.createEntityTable(docEntities[, resultEntities])`: Create an entity table from the document entity table. Return `resultEntities`.
- `xmlparser.replaceEntities(s, entityTable)`: Return a `string`.

### Document structure

```lua
document = {
  children = {
    { text=string } or { tag=string, attrs={ { name=string, value=string }, ... }, children={ ... } },
    ...
  },
  entities = { { name=string, value=string }, ... },
  tentities = { name=value, ... } -- only if subEntities = true
}
```


### Limitations

- Non-validating
- No DTD support
- No CDATA support
- Fails to detect any errors
- Ignore processing instructions
- Ignore DOCTYPE, parse only ENTITY
- If several attributes have the same name (allowed by the standard), only the last is kept.


## xmllpegparser API

- `xmllpegparser.parse(xmlstring[, visitorOrsubEntities[, visitorInitArgs...]])`: Return a tuple `document table, (string error or nil)` (see `visitor.finish`).
If `subEntities` is `true`, the entities are replaced and a `tentity` member is added to the document `table`.
- `xmllpegparser.parseFile(filename[, visitorOrsubEntities[, visitorInitArgs...]])`: Return a tuple `document table, error file or error document`.
- `xmllpegparser.defaultEntitiyTable()`: Return the default entity table (` { quot='"', ... }`).
- `xmllpegparser.createEntityTable(docEntities[, resultEntities])`: Create an entity table from the document entity table. Return `resultEntities`.
- `xmllpegparser.mkReplaceEntities(tableTable_or_func)`: Return a lpeg replace entities context: `str = ctx:match(str)`.
- `xmllpegparser.replaceEntities(s, entityTable_or_func)`: Return a `string`.
- `xmllpegparser.parser(visitor)`: return a parser (`{parse=function(xmlstring, visitorInitArgs...), parseFile=function(filename, visitorInitArgs...), __call=function(xmlstring, visitorInitArgs...)}`)
- `xmllpegparser.mkVisitor(evalEntities:bool, defaultEntities:table|function|nil, withoutPosition)`: `if not defaultEntities and evalEntities then defaultEntities = defaultEntityTable`. If `withoutPosition`, then `pos` parameter does not exist for the visitor functions except for `finish`.
- `xmllpegparser.lazyParser(visitorCreator)`
- `xmllpegparser.treeParser`: the default parser used by `xmllpegparser.parse(s, false)`
- `xmllpegparser.treeParserWithReplacedEntities`: the default parser used by `xmllpegparser.parse(s, true)`
- `xmllpegparser.treeParserWithoutPos`: parser without `pos` parameter
- `xmllpegparser.treeParserWithoutPosWithReplacedEntities`: parser without `pos` parameter
- `xmllpegparser.enableWithoutPosParser([bool])`: enable default parser with `treeParserWithoutPos*` version. `enableParserWithoutPos(false)` is same to `setDefaultParsers()`
- `xmllpegparser.setDefaultParsers(parser, parserWithReplacedEntities|bool|nil)`: Return previous parsers. If `parserWithReplacedEntities == true`, then `parserWithReplacedEntities = p`. `nil` value restore the default parser.

### Document structure (default parser)

```lua
-- pos member = index of string
document = {
  children = {
    { pos=integer, parent=table or nil, text=string[, cdata=true] } or
    { pos=integer, parent=table or nil, tag=string, attrs={ { name=string, value=string }, ... }, children={ ... } },
    ...
  },
  bad = { children={ ... } } -- if the number of closed nodes is greater than the open nodes. parent always refers to bad
  preprocessor = { { pos=integer, tag=string, attrs={ { name=string, value=string }, ... } },
  error = string, -- if error
  lastpos = numeric, -- last known position of parse()
  entities = { { pos=integer, name=string, value=string }, ... },
  tentities = { name=value, ... } -- only if subEntities = true
}
```

### Visitor structure

Each member is optionnal.

```lua
{
  withPos = bool -- indicates if pos parameter exists in function parameter (except `finish`)
  init = function(...), -- called before parsing, returns the position of the beginning of macth or nil
  finish = function(err, pos, xmlstring), -- called after parsing
  proc = function(pos, name, attrs), -- <?...?>
  entity = function(pos, name, value),
  doctype = function(pos, name, cat, path), -- called after all addEntity
  accuattr = function(table, name, value), -- `table` is an accumulator that will be transmitted to tag.attrs. Set to `false` for disable this function.
                                           -- If `nil` and `tag` is `not nil`, a default accumalator is used.
                                           -- If `false`, the accumulator is disabled.
                                           -- (`tag(pos, name, accuattr(accuattr({}, attr1, value1), attr2, value2)`)
  tag = function(pos, name, attrs), -- for a new tag (`<a>` or `<a/>`)
  open = function(), -- only for a open node (`<a>`), called after `tag`.
  close = function(name),
  text = function(pos, text),
  cdata = function(pos, text), -- or `text` if nil 
  comment = function(str)
}
```

### Default parser limitations

- Non-validating
- No DTD support
- Ignore processing instructions
- Ignore DOCTYPE, parse only ENTITY
- If several attributes have the same name (allowed by the standard), only the last is kept.


## Licence

[MIT license](LICENSE)


<!-- https://github.com/jonathanpoelen/lua-xmlparser -->
