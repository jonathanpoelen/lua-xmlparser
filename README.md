# lua-xmlparser

`xmlparser` is a fast XML parser written entirely in Lua 5.

This implementation is limited. For an even faster parser with more functionality, look at [lua-xmllpegparser](https://github.com/jonathanpoelen/lua-xmllpegparser).

<!-- summary -->
1. [Installation](#installation)
2. [Test](#test)
3. [xmlparser API](#xmlparser-api)
    1. [Document structure](#document-structure)
    2. [Limitations](#limitations)
5. [Licence](#licence)
<!-- /summary -->


## Installation

```bash
luarocks install --local https://raw.githubusercontent.com/jonathanpoelen/lua-xmlparser/master/xmlparser-2.2-0.rockspec

# Or in your local lua-xmlparser directory

luarocks make --local xmlparser-2.2-0.rockspec
```

## Test

Run `./example.lua`.

```sh
./example.lua [xmlfile [replaceentities]]
```

`replaceentities` = anything, only to enable replacement of entities.


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
    { text=string } or { tag=string, attrs={ [name]=value ... }, orderedattrs={ { name=string, value=string }, ... }, children={ ... } },
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


## Licence

[MIT license](LICENSE)


<!-- https://github.com/jonathanpoelen/lua-xmlparser -->
