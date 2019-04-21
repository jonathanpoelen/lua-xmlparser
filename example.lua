#!/usr/bin/env lua

function printelem(e, prefix)
  prefix = prefix or ''
  if e.tag then
    print(prefix .. '<' .. e.tag .. '>')
    prefix = '  ' .. prefix
    for name, value in pairs(e.attrs) do
      print(prefix .. '@' .. name .. ': ' .. value)
    end
    for i, child in pairs(e.children) do
      printelem(child, prefix)
    end
  else
    print(prefix .. '<> ' .. e.text)
  end
end

function printdoc(doc)
  print('Entities:')
  for i, e in pairs(doc.entities) do
    print('  ' .. e.name .. ': ' .. e.value)
  end
  print('Data:')
  for i, child in pairs(doc.children) do
    printelem(child, '  ')
  end
end

local args={...}
local parseFile = require(args[2] and 'xmllpegparser' or 'xmlparser').parseFile
local filename = args[1] and #args[1] > 0 and args[1] or 'example.xml'
local replaceEntities = args[3] and #args[3] > 0

local doc, err = parseFile(filename, replaceEntities)

printdoc(doc)
if err then
  print(err)
end
