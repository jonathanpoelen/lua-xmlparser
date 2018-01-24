#!/usr/bin/env lua

function str(t)
  local s = '{'
  for i, e in pairs(t) do
    if type(e) == 'table' then
      e = (i ~= 'parent') and str(e) or e.tag
    end
    s = s .. i .. ':' .. tostring(e) .. ','
  end
  return s .. '}'
end

r = 0

function eq(s, sxml, replaceEntities)
  local tdoc, err = xmllpegparser.parse(sxml, replaceEntities)
  local doc = str(tdoc)
  if err or s ~= doc then
    print('[FAILURE]\n  ' .. s .. '\n  ==\n  ' .. doc .. '\n with', sxml)
    if err then print('  ' .. err .. '/' .. #sxml) end
    r = r + 1
  end
end


require('xmlparser2')

eq('{preprocessor:{},entities:{},children:{1:{attrs:{},parent:nil,pos:1,children:{},tag:a,},2:{attrs:{},parent:nil,pos:8,children:{1:{parent:b,text:ad,pos:11,},},tag:b,},3:{attrs:{},parent:nil,pos:17,children:{},tag:c,},4:{attrs:{},parent:nil,pos:21,children:{1:{attrs:{},parent:d,pos:24,children:{1:{parent:e,text:ds,pos:27,},},tag:e,},},tag:d,},5:{attrs:{},parent:nil,pos:37,children:{1:{parent:f,text:a,pos:40,},2:{attrs:{},parent:f,pos:41,children:{},tag:g,},3:{parent:f,text:b,pos:45,},},tag:f,},},}',
   '<a></a><b>ad</b><c/><d><e>ds</e></d><f>a<g/>b</f>')
eq('{preprocessor:{},entities:{},children:{1:{attrs:{name:value,},parent:nil,pos:1,children:{},tag:a,},2:{attrs:{name:value,},parent:nil,pos:18,children:{},tag:b,},3:{attrs:{name:value,},parent:nil,pos:41,children:{},tag:c,},4:{attrs:{name:value,name2:value2,},parent:nil,pos:60,children:{},tag:d,},},}',
   '<a name="value"/><b   name  =  "value"/><c name="value"  /><d name="value"  name2="value2"/>')
eq('{preprocessor:{},entities:{},children:{1:{attrs:{name:v>a,},parent:nil,pos:1,children:{},tag:a,},2:{parent:nil,text:> b,pos:16,},3:{attrs:{name:>,},parent:nil,pos:19,children:{1:{parent:c,text:d,pos:31,},},tag:c,},4:{attrs:{name:a,},parent:nil,pos:36,children:{1:{parent:e,text:>f,pos:48,},},tag:e,},},}',
   '<a name="v>a"/>> b<c name=">">d</c><e name="a">>f</e>')
eq('{preprocessor:{},entities:{},children:{1:{attrs:{},parent:nil,pos:1,children:{1:{parent:a,text:b,pos:5,},},tag:a,},},}',
   '<a> b </a>')
eq('{preprocessor:{},entities:{1:{value:fdd>d,name:e1,pos:29,},2:{value:a,name:e2,pos:53,},},children:{1:{attrs:{},parent:nil,pos:72,children:{1:{parent:a,text:b,pos:75,},},tag:a,},},}',
   '<!DOCTYPE l SYSTEM "l.dtd"[ <!ENTITY e1   "fdd>d">  <!ENTITY e2 "a"> ]><a>b</a>')
eq('{tentities:{tab:\t,e2:a,gt:>,quot:",amp:&,e1:fdd>d,apos:\',nbsp: ,lt:<,},preprocessor:{},entities:{1:{value:fdd>d,name:e1,pos:29,},2:{value:a,name:e2,pos:53,},},children:{1:{attrs:{},parent:nil,pos:72,children:{1:{parent:a,text:fdd>ddsa;,pos:75,},},tag:a,},},}',
   '<!DOCTYPE l SYSTEM "l.dtd" [<!ENTITY e1   "fdd>d">  <!ENTITY e2 "a"> ]><a>&e1;ds&e2;;</a>', true)

os.exit(r)
