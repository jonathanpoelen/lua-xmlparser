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

local setmetatable, string, pairs, tostring, io = setmetatable, string, pairs, tostring, io
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

local accuAttr = function(a,k,v)
  a[k] = v
  return a
end

local mt = {__call = function(_, ...) return _.parse(...) end}

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

local _parser = function(v)
  local Comment = v.comment and CComment / v.comment or Comment
  local Comments = Space0 * (Comment * Space0)^0

  local Attrs = (v.accuattr or (v.tag and v.accuattr ~= false)) and
    Cf(Ct'' * (Space1 * CAttr)^0, v.accuattr or accuAttr) * Space0 or
              (Space1 *  Attr)^0                          * Space0

  local Preproc = v.proc and
    (Comments * I * '<?' * CName * Attrs * '?>' / v.proc)^0 or
    (Comments *     '<?' *  Name * Attrs * '?>'         )^0

  local Entities = v.entity and
    (Comments * Cg(I * CEntity) / v.entity)^0 or
    (Comments *         Entity            )^0

  local Doctype = v.doctype and
    Comments * ('<!DOCTYPE' * Space1 * I * CName * Space1 * C(R'AZ'^1) * Space1 * CString * Space0 * (P'>' + '[' * Entities * Comments * ']>') / v.doctype)^-1 or
    Comments * ('<!DOCTYPE' * Space1 *      Name * Space1 *  (R'AZ'^1) * Space1 *  String * Space0 * (P'>' + '[' * Entities * Comments * ']>')            )^-1

  local Tag = v.tag and
    '<' * I * CName * Attrs / v.tag or
    '<' *      Name * Attrs

  local Open = v.open and
    P'>' / v.open + '/>' or
    P'>'          + '/>'

  local Close = v.close and
    '</' * I * CName / v.close * Space0 * '>' or
    '</' *      Name           * Space0 * '>'

  local Text = v.text and
    I * C((Space0 * (1-S" \n\t<")^1)^1) / v.text or
         ((Space0 * (1-S" \n\t<")^1)^1)

  local Cdata = (v.cdata or v.text) and
    '<![CDATA[' * I * C((1 - P']]>')^0) * ']]>' / (v.cdata or v.text) or
    '<![CDATA[' *      ((1 - P']]>')^0) * ']]>'

  local G = Preproc * Doctype * (Space0 * (Tag * Open + Close + Comment + Cdata + Text))^0 * Space0 * I

  local init, finish = (v.init or noop), (v.finish or noop)

  return function(s, ...)
    init(...)
    local pos = G:match(s)
    local err = nil
    if #s >= pos then
      err = 'parse error at position ' .. tostring(pos)
    end

    local doc, verr = finish(err)
    if not verr and err then
      verr = err
    end

    return doc, verr
  end
end


function parser(v)
  return mkparser(_parser(v))
end

function defaultEntityTable()
  return { quot='"', apos='\'', lt='<', gt='>', amp='&', tab='\t', nbsp=' ', }
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


local mkTreeParser = function(evalEntities)
  local elem, doc, SubEntity, accuattr, doctype, cdata, text

  if evalEntities then
    SubEntity = Cs((P'&' * C((1-P';')^1) * P';' / defaultEntityTable() + 1)^0)
    accuattr = function(a,k,v)
      a[k] = SubEntity:match(v)
      return a
    end
    doctype = function(pos, name, cat, path)
      doc.tentities = createEntityTable(doc.entities)
      SubEntity = Cs((P'&' * C((1-P';')^1) * P';' / doc.tentities + 1)^0)
    end
    cdata = function(pos, text)
      elem.children[#elem.children+1] = {pos=pos-9, parent=elem, text=SubEntity:match(text), cdata=true}
    end
    text = function(pos, text)
      elem.children[#elem.children+1] = {pos=pos, parent=elem, text=SubEntity:match(text)}
    end
  else
    -- accuattr = accuAttr
    -- doctype = noop
    cdata = function(pos, text)
      elem.children[#elem.children+1] = {pos=pos-9, parent=elem, text=text, cdata=true}
    end
    text = function(pos, text)
      elem.children[#elem.children+1] = {pos=pos, parent=elem, text=text}
    end
  end

  return {
    accuattr=accuattr,
    doctype=doctype,
    cdata=cdata,
    text=text,
    init=function()
      elem = {children={}, bad={children={}}};
      doc = {preprocessor={}, entities={}, document=elem}
      elem.parent = bad
      elem.bad.parent = elem.bad
    end,
    finish=function(err)
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
      return doc, err
    end,
    proc=function(pos, name, attrs)
      doc.preprocessor[#doc.preprocessor+1] = {tag=name, attrs=attrs, pos=pos}
    end,
    entity=function(pos, k, v)
      doc.entities[#doc.entities+1] = {name=k, value=v, pos=pos}
    end,
    tag=function(pos, name, attrs)
      elem.children[#elem.children+1] = {tag=name, attrs=attrs, pos=pos-1, parent=elem, children={}}
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

treeParser = lazyParser(function() return mkTreeParser() end)
treeParserWithReplacedEntities = lazyParser(function() return mkTreeParser(true) end)

local getParser = function(visitorOrEvalEntities)
  return (not visitorOrEvalEntities and treeParser) or
         (visitorOrEvalEntities == true and treeParserWithReplacedEntities) or
         parser(visitorOrEvalEntities)
end

function parse(s, visitorOrEvalEntities, ...)
  return getParser(visitorOrEvalEntities).parse(s, ...)
end

function parseFile(filename, visitorOrEvalEntities, ...)
  return getParser(visitorOrEvalEntities).parseFile(filename, ...)
end
