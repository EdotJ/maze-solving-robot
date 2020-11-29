local type = type;
local assert = assert;
local strformat = string.format;
--- constants
local TRUE = {
    ['1'] = true,
    ['t'] = true,
    ['T'] = true,
    ['true'] = true,
    ['TRUE'] = true,
    ['True'] = true,
};
local FALSE = {
    ['0'] = false,
    ['f'] = false,
    ['F'] = false,
    ['false'] = false,
    ['FALSE'] = false,
    ['False'] = false,
};


--- toboolean
-- @param str
-- @return bool
-- @return err
local function toboolean( str )
    assert( type( str ) == 'string', 'str must be string' )

    if TRUE[str] == true then
        return true;
    elseif FALSE[str] == false then
        return false;
    else
        return false, strformat( 'cannot convert %q to boolean', str );
    end
end


return toboolean;