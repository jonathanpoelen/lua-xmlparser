-- from https://github.com/jonathanpoelen/xmlparser

local lpeg = require'lpeg'
local S = lpeg.S
local C = lpeg.C
local R = lpeg.R
local Ct = lpeg.Ct
local Cg = lpeg.Cg
local Cf = lpeg.Cf
local Cs = lpeg.Cs
local P = lpeg.P
local I = lpeg.Cp()

local setmetatable, string, pairs, tostring, io, type, rawset = setmetatable, string, pairs, tostring, io, type, rawset
-- local print = print

module "xmllpegparser"

local Space = S' \n\t'
local Space0 = Space^0
local Space1 = Space^1
local  String = (S"'" *   (1-S"'")^0  * S"'") + (S'"' *   (1-S'"')^0  * S'"')
local CString = (S"'" * C((1-S"'")^0) * S"'") + (S'"' * C((1-S'"')^0) * S'"')
local  Name = ((R('az','AZ') + S'_') * (R('az','AZ') + S'_-:' + R'09')^0)
local CName = C(Name)
local  Attr =   ( Name * Space0 * '=' * Space0 *  String )
local CAttr = Cg(CName * Space0 * '=' * Space0 * CString)
local  Comment = '<!--' *  (1-P'-->')^0 * '-->'
local CComment = '<!--' * C(1-P'-->')^0 * '-->'
local  Entity =   ('<!ENTITY' * Space1 *  Name * Space1 *  String * Space0 * '>')
local CEntity = Cg('<!ENTITY' * Space1 * CName * Space1 * CString * Space0 * '>')

local noop = function()end

local mt = {__call = function(_, ...) return _.parse(...) end}

local addI = function(x) return I * x end
local ident = function(x) return x end

local _parser = function(v)
  local mark = (v.withpos and addI or ident)

  local Comment = v.comment and CComment / v.comment or Comment
  local Comments = Space0 * (Comment * Space0)^0

  local Attrs = (v.accuattr or (v.tag and v.accuattr ~= false)) and
    Cf(Ct'' * (Space1 * CAttr)^0, v.accuattr or rawset) * Space0 or
              (Space1 *  Attr)^0                        * Space0

  local Preproc = v.proc and
    (Comments * mark('<?') * CName * Attrs * '?>' / v.proc)^0 or
    (Comments *      '<?'  *  Name * Attrs * '?>'         )^0

  local Entities = v.entity and
    (Comments * Cg(mark(CEntity)) / v.entity)^0 or
    (Comments *          Entity             )^0

  local Doctype = v.doctype and
    Comments * ('<!DOCTYPE' * Space1 * mark(CName) * Space1 * C(R'AZ'^1) * Space1 * CString * Space0 * (P'>' + '[' * Entities * Comments * ']>') / v.doctype)^-1 or
    Comments * ('<!DOCTYPE' * Space1 *       Name  * Space1 *  (R'AZ'^1) * Space1 *  String * Space0 * (P'>' + '[' * Entities * Comments * ']>')            )^-1

  local Tag = v.tag and
    '<' * mark(CName) * Attrs / v.tag or
    '<' *       Name  * Attrs

  local Open = v.open and
    P'>' / v.open + '/>' or
    P'>'          + '/>'

  local Close = v.close and
    '</' * mark(CName) / v.close * Space0 * '>' or
    '</' *       Name            * Space0 * '>'

  local Text = v.text and
    mark(C((Space0 * (1-S" \n\t<")^1)^1)) / v.text or
          ((Space0 * (1-S" \n\t<")^1)^1)

  local Cdata = (v.cdata or v.text) and
    '<![CDATA[' * mark(C((1 - P']]>')^0) * ']]>') / (v.cdata or v.text) or
    '<![CDATA[' *       ((1 - P']]>')^0) * ']]>'

  local G = Preproc * Doctype * (Space0 * (Tag * Open + Close + Comment + Cdata + Text))^0 * Space0 * I

  local init, finish = (v.init or noop), (v.finish or noop)

  return function(s, ...)
    local err
    local pos = init(...)
    pos = G:match(s, pos)
    if #s >= pos then
      err = 'parse error at position ' .. tostring(pos)
    end

    local doc, verr = finish(err, pos, s)
    return doc, (verr == nil and err or verr)
  end
end


local mkparser = function(pf)
  local p
  p = setmetatable({
    parse     = pf,
    parseFile = function(filename, ...)
      local f, err = io.open(filename)
      if f then return p.parse(f:read'*a', ...) end
      return f, err
    end,
  }, mt)
  return p
end

function parser(v)
  return mkparser(_parser(v))
end

function defaultEntityTable()
  return { quot='"', apos='\'', lt='<', gt='>', amp='&', tab='\t', nbsp=' ', }
end

local DeclEntity = P'&' * C((1-P';')^1) * P';'

function mkReplaceEntities(repl)
  return Cs((DeclEntity / repl + 1)^0)
end

function replaceEntities(s, entities)
  return s:gsub('&([^;]+);', entities)
end

function createEntityTable(docEntities, resultEntities)
  entities = resultEntities or defaultEntityTable()
  for _,e in pairs(docEntities) do
    e.value = replaceEntities(e.value, entities)
    entities[e.name] = e.value
  end
  return entities
end


function mkVisitor(evalEntities, defaultEntities, withoutPosition)
  local elem, doc, SubEntity, accuattr, doctype, cdata, text
  local mkDefaultEntities = defaultEntities and (
    type(defaultEntities) == 'table' and function()
      local t = {}
      for k,e in pairs(defaultEntities) do
        t[k] = e
      end
      return t
    end
    or defaultEntities
  ) or defaultEntityTable

  if evalEntities then
    accuattr = function(a,k,v)
      a[k] = SubEntity:match(v)
      return a
    end

    doctype = withoutPosition and function(name, cat, path)
      doc.tentities = createEntityTable(doc.entities, mkDefaultEntities())
      SubEntity = mkReplaceEntities(doc.tentities)
    end or function(pos, name, cat, path)
      doc.tentities = createEntityTable(doc.entities, mkDefaultEntities())
      SubEntity = mkReplaceEntities(doc.tentities)
    end

    cdata = withoutPosition and function(text)
      elem.children[#elem.children+1] = {parent=elem, text=SubEntity:match(text), cdata=true}
    end or function(text)
      elem.children[#elem.children+1] = {parent=elem, text=SubEntity:match(text), cdata=true, pos=pos-9}
    end

    text = withoutPosition and function(text)
      elem.children[#elem.children+1] = {parent=elem, text=SubEntity:match(text)}
    end or function(pos, text)
      elem.children[#elem.children+1] = {parent=elem, text=SubEntity:match(text), pos=pos}
    end
  else
    -- accuattr = noop
    -- doctype = noop
    cdata = withoutPosition and function(text)
      elem.children[#elem.children+1] = {parent=elem, text=text, cdata=true}
    end or function(pos, text)
      elem.children[#elem.children+1] = {parent=elem, text=text, cdata=true, pos=pos-9}
    end

    text = withoutPosition and function(text)
      elem.children[#elem.children+1] = {parent=elem, text=text}
    end or function(pos, text)
      elem.children[#elem.children+1] = {parent=elem, text=text, pos=pos}
    end
  end

  return {
    withpos=not withoutPosition,
    accuattr=accuattr,
    doctype=doctype,
    cdata=cdata,
    text=text,

    init=function()
      elem = {children={}, bad={children={}}};
      doc = {preprocessor={}, entities={}, document=elem}
      elem.parent = bad
      elem.bad.parent = elem.bad
      if evalEntities then
        SubEntity = mkReplaceEntities(mkDefaultEntities())
      end
    end,

    finish=function(err, pos)
      if doc.document ~= elem then
        err = (err and err .. ' ' or '') .. 'No matching close for ' .. tostring(elem.tag) .. ' at position ' .. tostring(elem.pos)
      end
      doc.bad = doc.document.bad
      doc.bad.parent = nil
      doc.document.bad = nil
      doc.document.parent = nil
      doc.children = doc.document.children
      doc.document = nil
      if 0 == #doc.bad.children then
        doc.bad = nil
      else
        err = (err and err .. ' ' or '') .. 'No matching open for ' .. tostring(doc.bad.children[1].tag) .. ' at position ' .. tostring(doc.bad.children[1].pos)
      end
      doc.lastpos = pos
      if err then
        doc.error = err
      end
      return doc, err
    end,

    proc=withoutPosition and function(name, attrs)
      doc.preprocessor[#doc.preprocessor+1] = {tag=name, attrs=attrs}
    end or function(pos, name, attrs)
      doc.preprocessor[#doc.preprocessor+1] = {tag=name, attrs=attrs, pos=pos}
    end,

    entity=withoutPosition and function(k, v)
      doc.entities[#doc.entities+1] = {name=k, value=v}
    end or function(pos, k, v)
      doc.entities[#doc.entities+1] = {name=k, value=v, pos=pos}
    end,

    tag=withoutPosition and function(name, attrs)
      elem.children[#elem.children+1] = {tag=name, attrs=attrs, parent=elem, children={}}
    end or function(pos, name, attrs)
      elem.children[#elem.children+1] = {tag=name, attrs=attrs, parent=elem, children={}, pos=pos-1}
    end,

    open=function()
      elem = elem.children[#elem.children]
    end,

    close=function()
      elem = elem.parent
    end,
  }
end

function lazyParser(visitorCreator)
  local p
  p = mkparser(function(...) p.parse = _parser(visitorCreator()); return p.parse(...) end)
  return p
end

treeParser = lazyParser(function() return mkVisitor() end)
treeParserWithReplacedEntities = lazyParser(function() return mkVisitor(true) end)
treeParserWithoutPos = lazyParser(function() return mkVisitor(nil,nil,true) end)
treeParserWithoutPosWithReplacedEntities = lazyParser(function() return mkVisitor(true,nil,true) end)

local _defaultParser, _defaultParserWithReplacedEntities = treeParser, treeParserWithReplacedEntities

function enableWithoutPosParser(b)
  if b == nil or b == true then
    _defaultParser, _defaultParserWithReplacedEntities = treeParserWithoutPos, treeParserWithoutPosWithReplacedEntities
  else
    _defaultParser, _defaultParserWithReplacedEntities = treeParser, treeParserWithReplacedEntities
  end
end

function setDefaultParsers(p, pWithReplacedEntities)
  local r1, r2 = _defaultParser, _defaultParserWithReplacedEntities
  _defaultParser = p or treeParser
  if pWithReplacedEntities == true then
    _defaultParserWithReplacedEntities = _defaultParser
  elseif pWithReplacedEntities == false then
    _defaultParserWithReplacedEntities = treeParserWithReplacedEntities
  else
    _defaultParserWithReplacedEntities = pWithReplacedEntities or treeParserWithReplacedEntities or _defaultParser
  end
  return r1, r2
end

local getParser = function(visitorOrEvalEntities)
  return (not visitorOrEvalEntities and _defaultParser) or
         (visitorOrEvalEntities == true and _defaultParserWithReplacedEntities) or
         parser(visitorOrEvalEntities)
end

function parse(s, visitorOrEvalEntities, ...)
  return getParser(visitorOrEvalEntities).parse(s, ...)
end

function parseFile(filename, visitorOrEvalEntities, ...)
  return getParser(visitorOrEvalEntities).parseFile(filename, ...)
end
