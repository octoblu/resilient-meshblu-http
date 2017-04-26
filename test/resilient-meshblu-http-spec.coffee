{describe,beforeEach,afterEach,expect,it} = global
enableDestroy        = require 'server-destroy'
shmock               = require '@octoblu/shmock'
ResilientMeshbluHttp = require '../'

describe 'ResilientMeshbluHttp', ->
  beforeEach ->
    @meshblu = shmock()
    enableDestroy(@meshblu)
    @meshbluPort = @meshblu.address().port
    @sut = new ResilientMeshbluHttp {
      timeout: 500
      meshbluConfig:
        uuid: 'some-uuid'
        token: 'some-token'
        hostname: 'localhost'
        protocol: 'http'
        port: @meshbluPort
    }

  afterEach ->
    @meshblu.destroy()

  describe '->generateAndStoreToken', ->
    describe 'when it works the first time', ->
      beforeEach (done) ->
        auth = new Buffer('some-uuid:some-token').toString('base64')
        @firstAttempt = @meshblu.post '/devices/the-uuid/tokens'
          .set 'Authorization', "Basic #{auth}"
          .reply 201, {
            token: 'yes'
          }
        @sut.generateAndStoreToken 'the-uuid', done

      it 'should do the first attempt', ->
        @firstAttempt.done()

    describe 'when it fails once', ->
      beforeEach (done) ->
        auth = new Buffer('some-uuid:some-token').toString('base64')
        @firstAttempt = @meshblu.post '/devices/the-uuid/tokens'
          .set 'Authorization', "Basic #{auth}"
          .reply 504

        @secondAttempt = @meshblu.post '/devices/the-uuid/tokens'
          .set 'Authorization', "Basic #{auth}"
          .reply 201, {
            token: 'yes'
          }
        @sut.generateAndStoreToken 'the-uuid', done

      it 'should do the first attempt', ->
        @firstAttempt.done()

      it 'should do the second attempt', ->
        @secondAttempt.done()

    describe 'when it times out', ->
      beforeEach (done) ->
        auth = new Buffer('some-uuid:some-token').toString('base64')
        @firstAttempt = @meshblu.post '/devices/the-uuid/tokens'
          .set 'Authorization', "Basic #{auth}"
          .reply 504

        @secondAttempt = @meshblu.post '/devices/the-uuid/tokens'
          .set 'Authorization', "Basic #{auth}"
          .delay 800
          .reply 204

        @thirdAttempt = @meshblu.post '/devices/the-uuid/tokens'
          .set 'Authorization', "Basic #{auth}"
          .reply 201, {
            token: 'yes'
          }

        @sut.generateAndStoreToken 'the-uuid', done

      it 'should do the first attempt', ->
        @firstAttempt.done()

      it 'should do the second attempt', ->
        @secondAttempt.done()

      it 'should do the third attempt', ->
        @thirdAttempt.done()

    describe 'when it exceeded the number of requests', ->
      beforeEach (done) ->
        auth = new Buffer('some-uuid:some-token').toString('base64')
        @firstAttempt = @meshblu.post '/devices/the-uuid/tokens'
          .set 'Authorization', "Basic #{auth}"
          .reply 504

        @secondAttempt = @meshblu.post '/devices/the-uuid/tokens'
          .set 'Authorization', "Basic #{auth}"
          .reply 504

        @thirdAttempt = @meshblu.post '/devices/the-uuid/tokens'
          .set 'Authorization', "Basic #{auth}"
          .reply 504

        @fourthAttempt = @meshblu.post '/devices/the-uuid/tokens'
          .set 'Authorization', "Basic #{auth}"
          .reply 504

        @fifthAttempt = @meshblu.post '/devices/the-uuid/tokens'
          .set 'Authorization', "Basic #{auth}"
          .reply 504

        @sixthAttempt = @meshblu.post '/devices/the-uuid/tokens'
          .set 'Authorization', "Basic #{auth}"
          .reply 504

        @sut.generateAndStoreToken 'the-uuid', (@error) =>
          done()

      it 'should have an error of 504', ->
        expect(@error).to.exist
        expect(@error.code).to.equal 504

      it 'should do the first attempt', ->
        @firstAttempt.done()

      it 'should do the second attempt', ->
        @secondAttempt.done()

      it 'should do the third attempt', ->
        @thirdAttempt.done()

      it 'should do the fourth attempt', ->
        @fourthAttempt.done()

      it 'should do the fifth attempt', ->
        @fifthAttempt.done()

      it 'should NOT do the sixth attempt', ->
        expect(@sixthAttempt.isDone).to.be.false

  describe '->device', ->
    beforeEach (done) ->
      auth = new Buffer('some-uuid:some-token').toString('base64')
      @firstAttempt = @meshblu.get '/v2/devices/the-uuid'
        .set 'Authorization', "Basic #{auth}"
        .reply 504

      @secondAttempt = @meshblu.get '/v2/devices/the-uuid'
        .set 'Authorization', "Basic #{auth}"
        .reply 200, {
          uuid: 'the-uuid'
          other: true
        }
      @sut.device 'the-uuid', done

    it 'should do the first attempt', ->
      @firstAttempt.done()

    it 'should do the second attempt', ->
      @secondAttempt.done()

  describe '->message', ->
    beforeEach (done) ->
      auth = new Buffer('some-uuid:some-token').toString('base64')
      @firstAttempt = @meshblu.post '/messages'
        .set 'Authorization', "Basic #{auth}"
        .send {
          some: 'message'
        }
        .reply 504

      @secondAttempt = @meshblu.post '/messages'
        .set 'Authorization', "Basic #{auth}"
        .send {
          some: 'message'
        }
        .reply 201

      @sut.message { some: 'message' }, done

    it 'should do the first attempt', ->
      @firstAttempt.done()

    it 'should do the second attempt', ->
      @secondAttempt.done()

  describe '->search', ->
    beforeEach (done) ->
      auth = new Buffer('some-uuid:some-token').toString('base64')
      @firstAttempt = @meshblu.post '/search/devices'
        .set 'Authorization', "Basic #{auth}"
        .send {
          owner: 'some-customer-uuid',
          connector:
            $in:[
              'meshblu-connector-skype'
              'meshblu-connector-powermate'
            ]
          }
        .reply 504
      @secondAttempt = @meshblu.post '/search/devices'
        .set 'Authorization', "Basic #{auth}"
        .send {
          owner: 'some-customer-uuid',
          connector:
            $in:[
              'meshblu-connector-skype'
              'meshblu-connector-powermate'
            ]
          }
        .reply 200, [
          {
            "uuid": "some-connector-uuid-1"
            "type": "device:skype:1"
            "genisys": {
              room: {
                name: "some-room"
              }
            }
            "status": {
              "$ref": "meshbludevice://some-status-device-uuid-1"
            }
          }
        ]

      query = {
        owner: 'some-customer-uuid',
        connector:
          $in:[
            'meshblu-connector-skype'
            'meshblu-connector-powermate'
          ]
        }
      @sut.search query, {}, done

    it 'should do the first attempt', ->
      @firstAttempt.done()

    it 'should do the second attempt', ->
      @secondAttempt.done()
