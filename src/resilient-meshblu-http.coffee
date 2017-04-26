_           = require 'lodash'
MeshbluHttp = require 'meshblu-http'
async       = require 'async'

class ResilientMeshbluHttp
  constructor: ({ meshbluConfig, @retryConfig, @timeout }) ->
    throw new Error 'ResilientMeshbluHttp: requires meshbluConfig' unless meshbluConfig?
    @timeout     ?= 30 * 1000
    @retryConfig ?= { tries: 5, interval: 10 }
    meshbluConfig = _.cloneDeep meshbluConfig
    meshbluConfig.timeout = @timeout
    @meshbluHttp = new MeshbluHttp meshbluConfig

  generateAndStoreToken: (uuid, callback) =>
    async.retry @retryConfig, (next) =>
      @meshbluHttp.generateAndStoreToken uuid, next
    , callback

  device: (uuid, callback) =>
    async.retry @retryConfig, (next) =>
      @meshbluHttp.device uuid, next
    , callback

  search: (query,projection,callback) =>
    async.retry @retryConfig, (next) =>
      @meshbluHttp.search query,projection, next
    , callback

  message: (message, callback) =>
    async.retry @retryConfig, (next) =>
      @meshbluHttp.message message, next
    , callback

module.exports = ResilientMeshbluHttp
