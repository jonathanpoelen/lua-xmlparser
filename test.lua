#!/usr/bin/env lua

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


require('xmlparser')

eq('{children:{1:{attrs:{},children:{},tag:a,},2:{attrs:{},children:{1:{text:ad,},},tag:b,},3:{attrs:{},children:{},tag:c,},4:{attrs:{},children:{1:{attrs:{},children:{1:{text:ds,},},tag:e,},},tag:d,},5:{attrs:{},children:{1:{text:a,},2:{attrs:{},children:{},tag:g,},3:{text:b,},},tag:f,},},entities:{},}',
   '<a></a><b>ad</b><c/><d><e>ds</e></d><f>a<g/>b</f>')
eq('{children:{1:{attrs:{name:value,},children:{},tag:a,},2:{attrs:{name:value,},children:{},tag:b,},3:{attrs:{name:value,},children:{},tag:c,},4:{attrs:{name:value,name2:value2,},children:{},tag:d,},},entities:{},}',
   '<a name="value"/><b   name  =  "value"/><c name="value"  /><d name="value"  name2="value2"/>')
eq('{children:{1:{attrs:{name:v>a,},children:{},tag:a,},2:{text:> b,},3:{attrs:{name:>,},children:{1:{text:d,},},tag:c,},4:{attrs:{name:a,},children:{1:{text:>f,},},tag:e,},},entities:{},}',
   '<a name="v>a"/>> b<c name=">">d</c><e name="a">>f</e>')
eq('{children:{1:{attrs:{},children:{1:{text:b,},},tag:a,},},entities:{},}',
   '<a> b </a>')
eq('{children:{1:{attrs:{},children:{1:{text:b,},},tag:a,},},entities:{1:{name:e1,value:fdd>d,},2:{name:e2,value:a,},},}',
   '<!DOCTYPE l SYSTEM "l.dtd"[ <!ENTITY e1   "fdd>d">  <!ENTITY e2 "a"> ]><a>b</a>')
eq('{children:{1:{attrs:{},children:{1:{text:fdd>ddsa;,},},tag:a,},},entities:{1:{name:e1,value:fdd>d,},2:{name:e2,value:a,},},tentities:{amp:&,apos:\',e1:fdd>d,e2:a,gt:>,lt:<,nbsp: ,quot:",tab:\t,},}',
   '<!DOCTYPE l SYSTEM "l.dtd" [<!ENTITY e1   "fdd>d">  <!ENTITY e2 "a"> ]><a>&e1;ds&e2;;</a>', true)

os.exit(r)
