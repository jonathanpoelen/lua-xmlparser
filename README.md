# xmlparser

xmlparser is an fast XML parser written entirely in Lua 5.


# Installation

```bash
luarocks install xml2lua
```

Or run the examples directly.


# API

- `xmlparser.parse(xmlstring)`
- `xmlparser.parse_file(filename)`

## Document structure

```lua
document = {
  children = {
    { text=string } or {tag=string, attrs={ { name=string, value=string }, ... }, children={ ... } },
    ...
  },
  entities = { { name=string, value=string }, ... }
}
```


# Limitations

- Non-validating
- No DTD support
- No CDATA support
- Fails to detect any errors
- Ignore processing instructions
- Ignore DOCTYPE, parse only ENTITY
- If several attributes have the same name (allowed by the standard), only the last is kept.


# Licence

[MIT license](LICENSE)


<!-- https://github.com/jonathanpoelen/xmlparser -->
