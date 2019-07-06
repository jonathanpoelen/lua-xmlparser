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

local parseFile = require('xmlparser').parseFile
local filename = arg[1] and #arg[1] > 0 and arg[1] or 'example.xml'
local replaceEntities = arg[2] and #arg[2] > 0

local doc, err = parseFile(filename, replaceEntities)

printdoc(doc)
if err then
  io.stderr:write(err .. '\n')
end
