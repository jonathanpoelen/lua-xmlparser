#!/usr/bin/env lua

xmlparser = require('xmlparser')

function str(t)
  local orderedIndex = {}
  for i in pairs(t) do
    table.insert(orderedIndex, i)
  end
  table.sort(orderedIndex)

  local s, e = '{'
  for k, i in pairs(orderedIndex) do
    e = t[i]
    if type(e) == 'table' then
      e = str(e)
    end
    s = s .. i .. ':' .. e .. ','
  end
  return s .. '}'
end

r = 0

function eq(s, sxml, replaceEntities)
  local doc = str(xmlparser.parse(sxml, replaceEntities))
  if s ~= doc then
    print('[FAILURE]\n  ' .. s .. '\n  ==\n  ' .. doc .. '\n with', sxml)
    r = r + 1
  end
end

function feq(s, filename)
  local tdoc, err = xmlparser.parseFile(filename)
  local doc = str(tdoc)
  if err or s ~= doc then
    print('[FAILURE]\n  ' .. s .. '\n  ==\n  ' .. doc .. '\n with file', filename)
    if err then print('  ' .. err .. '/' .. filename) end
    r = r + 1
  end
end


eq('{children:{1:{attrs:{},children:{},orderedattrs:{},tag:a,},2:{attrs:{},children:{1:{text:ad,},},orderedattrs:{},tag:b,},3:{attrs:{},children:{},orderedattrs:{},tag:c,},4:{attrs:{},children:{1:{attrs:{},children:{1:{text:ds,},},orderedattrs:{},tag:e,},},orderedattrs:{},tag:d,},5:{attrs:{},children:{1:{text:a,},2:{attrs:{},children:{},orderedattrs:{},tag:g,},3:{text:b,},},orderedattrs:{},tag:f,},},entities:{},}',
   '<a></a><b>ad</b><c/><d><e>ds</e></d><f>a<g/>b</f>')
eq('{children:{1:{attrs:{name:value,},children:{},orderedattrs:{1:{name:name,value:value,},},tag:a,},2:{attrs:{name:value,},children:{},orderedattrs:{1:{name:name,value:value,},},tag:b,},3:{attrs:{name:value,},children:{},orderedattrs:{1:{name:name,value:value,},},tag:c,},4:{attrs:{name:value,name2:value2,},children:{},orderedattrs:{1:{name:name,value:value,},2:{name:name2,value:value2,},},tag:d,},},entities:{},}',
   '<a name="value"/><b   name  =  "value"/><c name="value"  /><d name="value"  name2="value2"/>')
eq('{children:{1:{attrs:{name:v>a,},children:{},orderedattrs:{1:{name:name,value:v>a,},},tag:a,},2:{text:> b,},3:{attrs:{name:>,},children:{1:{text:d,},},orderedattrs:{1:{name:name,value:>,},},tag:c,},4:{attrs:{name:a,},children:{1:{text:>f,},},orderedattrs:{1:{name:name,value:a,},},tag:e,},},entities:{},}',
   '<a name="v>a"/>> b<c name=">">d</c><e name="a">>f</e>')
eq('{children:{1:{attrs:{},children:{1:{text:b,},},orderedattrs:{},tag:a,},},entities:{},}',
   '<a> b </a>')
eq('{children:{1:{attrs:{},children:{1:{text:b,},},orderedattrs:{},tag:a,},},entities:{1:{name:e1,value:fdd>d,},2:{name:e2,value:a,},},}',
   '<!DOCTYPE l SYSTEM "l.dtd"[ <!ENTITY e1   "fdd>d">  <!ENTITY e2 "a"> ]><a>b</a>')
eq('{children:{1:{attrs:{},children:{1:{text:fdd>ddsa;,},},orderedattrs:{},tag:a,},},entities:{1:{name:e1,value:fdd>d,},2:{name:e2,value:a,},},tentities:{amp:&,apos:\',e1:fdd>d,e2:a,gt:>,lt:<,nbsp: ,quot:",tab:	,},}',
   '<!DOCTYPE l SYSTEM "l.dtd" [<!ENTITY e1   "fdd>d">  <!ENTITY e2 "a"> ]><a>&e1;ds&e2;;</a>', true)

feq('{children:{1:{attrs:{},children:{1:{attrs:{attribute:&entity1;,},children:{1:{text:something,},},orderedattrs:{1:{name:attribute,value:&entity1;,},},tag:lvl1,},2:{text:blah blah,},3:{attrs:{attr3:value3,attribute:value,otherattribute:value2,},children:{},orderedattrs:{1:{name:attribute,value:value,},2:{name:otherattribute,value:value2,},3:{name:attr3,value:value3,},},tag:lvl1,},4:{attrs:{},children:{1:{attrs:{},children:{1:{text:something,},},orderedattrs:{},tag:lvl2,},},orderedattrs:{},tag:other,},},orderedattrs:{},tag:xml,},},entities:{1:{name:entity1,value:something,},2:{name:entity2,value:test,},},}',
   'example.xml')

if r == 0 then
  print('Ok')
else
  os.exit(r)
end
