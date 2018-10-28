# xmlparser

`xmlparser` is an fast XML parser written entirely in Lua 5.

`xmllpegparser` is an implementation with a visitor and using [`lpeg`](http://www.inf.puc-rio.br/~roberto/lpeg/lpeg.html) for even more speed and features.


# Installation

```bash
luarocks install --local https://raw.githubusercontent.com/jonathanpoelen/lua-xmlparser/master/xmlparser-2.0-3.rockspec
luarocks install --local https://raw.githubusercontent.com/jonathanpoelen/lua-xmlparser/master/xmllpegparser-2.0-3.rockspec

# or in your directory

luarocks make --local xmlparser-2.0-3.rockspec
luarocks make --local xmllpegparser-2.0-3.rockspec
```

Or run the examples directly (`./example.lua [xmlfile [x]]`. `x` = something for enable xmllpegparser).


# xmlparser API

- `xmlparser.parse(xmlstring[, subEntities])`: Return a document `table` (see below).
If `subEntities` is `true`, the entities are replaced and a `tentity` member is added to the document `table`.
- `xmlparser.parseFile(filename[, subEntities])`: Return a tuple `document table, error file`.
- `xmlparser.defaultEntitiyTable()`: Return the default entity table (` { quot='"', ... }`).
- `xmlparser.createEntityTable(docEntities[, resultEntities])`: Create an entity table from the document entity table. Return `resultEntities`.
- `xmlparser.replaceEntities(s, entityTable)`: Return a `string`.

## Document structure

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


## Limitations

- Non-validating
- No DTD support
- No CDATA support
- Fails to detect any errors
- Ignore processing instructions
- Ignore DOCTYPE, parse only ENTITY
- If several attributes have the same name (allowed by the standard), only the last is kept.


# xmllpegparser API

- `xmllpegparser.parse(xmlstring[, visitorOrsubEntities[, visitorInitArgs...]])`: Return a tuple `document table, string error` (see below).
If `subEntities` is `true`, the entities are replaced and a `tentity` member is added to the document `table`.
- `xmllpegparser.parseFile(filename[, visitorOrsubEntities[, visitorInitArgs...]])`: Return a tuple `document table, error file or error document`.
- `xmllpegparser.defaultEntitiyTable()`: Return the default entity table (` { quot='"', ... }`).
- `xmllpegparser.createEntityTable(docEntities[, resultEntities])`: Create an entity table from the document entity table. Return `resultEntities`.
- `xmllpegparser.replaceEntities(s, entityTable)`: Return a `string`.
- `xmllpegparser.parser(visitor)`: return a parser (`{parse=function(xmlstring, visitorInitArgs...), parseFile=function(filename, visitorInitArgs...), __call=function(xmlstring, visitorInitArgs...)}`)
- `xmllpegparser.lazyParser(visitorCreator)`
- `xmllpegparser.treeParser`: the defauld parser used by `xmllpegparser.parse(s, false)`
- `xmllpegparser.treeParserWithReplacedEntities`: the defauld parser used by `xmllpegparser.parse(s, true)`

## Document structure (default parser)

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
  entities = { { pos=integer, name=string, value=string }, ... },
  tentities = { name=value, ... } -- only if subEntities = true
}
```

## Visitor structure

Each member is optionnal.

```lua
{
  init = function(...), -- called before parsing
  finish = function(err), -- called after parsing
  proc = function(pos, name, attrs), -- <?...?>
  entity = function(pos, name, value),
  doctype = function(pos, name, cat, path), -- called after all addEntity
  accuattr = function(table, name, value), -- `table` is an accumulator that will be transmitted to tag.attrs.
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

## Default parser limitations

- Non-validating
- No DTD support
- Ignore processing instructions
- Ignore DOCTYPE, parse only ENTITY
- If several attributes have the same name (allowed by the standard), only the last is kept.


# Licence

[MIT license](LICENSE)


<!-- https://github.com/jonathanpoelen/lua-xmlparser -->
