local io = io

module "xmlparser"

function parse(s)
  s = s:gsub('<!%-%-(.-)%-%->', '')

  local entities = {
    {name='quot', value='"'},
    {name='apos', value='\''},
    {name='lt', value='<'},
    {name='gt', value='>'},
    {name='amp', value='&'},
    {name='tab', value='\t'},
    {name='nbsp', value=' '},
  }
  local t, l, a = {}, {}

  local addtext = function(txt)
    if #txt ~= 0 then
      txt = txt:match('^(.*%S)')
      if #txt ~= 0 then
        t[#t+1] = {text=txt}
      end    
    end    
  end

  s:gsub('<([?!/]?)([-:_%w]+)([^>]*)>%s*([^<]*)', function(p, name, attrs, txt)
    -- open
    if #p == 0 then
      a = {}
      attrs:gsub('([-_%w]+)%s*=(.)(.-)(%2)', function(name, q, value)
        a[name] = value
      end)
      t[#t+1] = {tag=name, attrs=a, children={}}
      
      if attrs:sub(-1) ~= '/' then
        l[#l+1] = t
        t = t[#t].children
      end

      addtext(txt)
    -- close
    elseif '/' == p then
      t = l[#l]
      l[#l] = nil

      addtext(txt)
    -- DOCTYPE / ENTITY
    elseif '!' == p then
      local sub = name:sub(1,1)
      if 'D' == sub then
        attrs = attrs:gsub('^[^<]*<!ENTITY', '', 1)
      end
      if 'E' == sub or 'D' == sub then
        attrs:gsub('(%w+)%s+(.)(.-)(%2)', function(name, q, entity)
          entities[#entities+1] = {name=name, value=entity}
        end, 1)
      end
    -- elseif p == '?' then
    --   print('?  ' .. name .. ' // ' .. attrs .. '$$')
    -- elseif p == '-' then
    --   print('comment  ' .. name .. ' // ' .. attrs .. '$$')
    -- else
    --   print('o  ' .. #p .. ' // ' .. name .. ' // ' .. attrs .. '$$')
    end
  end)
  
  return {children=t, entities=entities}
end

function parse_file(filename)
  local f, err = io.open(filename)
  if not f then
    return f, err
  end
  return parse(f:read('*a'))
end
