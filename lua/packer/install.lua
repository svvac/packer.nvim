local a       = require('packer/async')
local util    = require('packer/util')
local display = require('packer/display')

local async = a.sync
local await = a.wait

local config = nil

local function install_plugin(plugin, display_win, results)
  local plugin_name = util.get_plugin_full_name(plugin)
  -- TODO: This will have to change when multiple packages are added
  local install_path = util.join_paths(config.pack_dir, plugin.opt and 'opt' or 'start', plugin.name)
  plugin.install_path = install_path
  return async(function()
    display_win:task_start(plugin_name, 'installing...')
    local r = await(plugin.installer(display_win))
    if r.ok then
      if plugin.run then
        plugin.run(plugin, install_path)
      end
      display_win:task_succeeded(plugin_name, 'installed')
    else
      display_win:task_failed(plugin_name, 'failed to install')
    end

    results.installs[plugin_name] = r
    results.plugins[plugin_name] = plugin
  end)
end

local function do_install(_, plugins, missing_plugins, results)
  results = results or {}
  results.installs = results.installs or {}
  results.plugins = results.plugins or {}
  local display_win = nil
  local tasks = {}
  if #missing_plugins > 0 then
    display_win = display.open(config.display.open_fn or config.display.open_cmd)
    for _, v in ipairs(missing_plugins) do
      if not plugins[v].disable then
        table.insert(tasks, install_plugin(plugins[v], display_win, results))
      end
    end
  end

  return tasks, display_win
end

local function cfg(_config)
  config = _config
end

local install = setmetatable({ cfg = cfg }, { __call = do_install })

return install
