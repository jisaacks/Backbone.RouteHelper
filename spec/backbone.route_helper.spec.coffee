# include reauired libraries
global._        = require "underscore"
global.Backbone = require "backbone"
global.qs       = require "../lib/qs"
sinon           = require "sinon"
stubber         = require "backbone.history_stub"

require "../lib/backbone.route_helper"

class SpecRouter extends Backbone.Router
  routes:
    ""                                              : "root"
    "i/am/jacks/:jacks"                             : "jacks"
    "paper/street/:soap"                            : "soap"
    "the/:nth/rule/of/fight/club/is/*rule"          : "rule"
    "his/name/is/:first/:last"                      : "funeral"
    "fight/club/:first/project/mayhem/:last"        : "order"
    "on/your/first/night/fighting/isnt(/:optional)" : "optional"
    "another(/thats:optional)"                      : "prefixed"

router = new SpecRouter()
stubber.stub()
Backbone.history.start()

RH = Backbone.RouteHelper
nv = (route) -> router.navigate route, trigger:true

describe "Backbone.RouteHelper", ->

  beforeEach ->
    nv ""

  it "tracks the current route", ->
    route = "i/am/jacks/colon"
    nv "i/am/jacks/colon"
    expect(RH.route()).toEqual(route)

  it "can build a route", ->
    route = RH.build("jacks").params(jacks: "liver").route()
    expect(route).toEqual("i/am/jacks/liver")

  it "can modify the current route", ->
    nv "paper/street/crimes"
    route = RH.modify().params(soap: "soap").route()
    expect(route).toEqual("paper/street/soap")

  it "works with splats", ->
      rt = RH.build("rule").params({
        nth: "first"
        rule: "do/not/talk/about/fight/club"
      }).route()
      should = "the/first/rule/of/fight/club/is/do/not/talk/about/fight/club"
      expect(rt).toEqual(should)

  it "can swap routes with same params", ->
    rh = RH.build("order").params({
      first: "robert"
      last: "paulson"
    })
    route = rh.modify("funeral").route()
    expect(route).toEqual("his/name/is/robert/paulson")

  it "works with querys", ->
    route = RH.build("root").query(q: "tyler").route()
    expect(route).toEqual("?q=tyler")

  it "can update params while maintaining query", ->
    nv RH.build("jacks").params(jacks: "foot").query(show: "all").route()
    route = RH.modify().params(jacks: "hand").route()
    expect(route).toEqual("i/am/jacks/hand?show=all")

  it "can update params and clear query", ->
    nv RH.build("jacks").params(jacks: "foot").query(show: "all").route()
    route = RH.modify().params(jacks: "hand").build().query().route()
    expect(route).toEqual("i/am/jacks/hand")

  it "works with optional params", ->
    # with optional param
    rt1 = RH.build("optional").params(optional: 2).route()
    expect(rt1).toEqual("on/your/first/night/fighting/isnt/2")
    # without optional params
    rt2 = RH.build("optional").route()
    expect(rt2).toEqual("on/your/first/night/fighting/isnt")

  it "works with prefixed optional params", ->
    # with optional param
    rt1 = RH.build("prefixed").params(optional: 2).route()
    expect(rt1).toEqual("another/thats2")
    # without optional params
    rt2 = RH.build("prefixed").route()
    expect(rt2).toEqual("another")

Backbone.history.stop()