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

class AmbiguousRouterA extends Backbone.Router
  routes:
    "ambiguous/a" : "ambiguous"
aaRouter = new AmbiguousRouterA()

class AmbiguousRouterB extends Backbone.Router
  routes:
    "ambiguous/b" : "ambiguous"
abRouter = new AmbiguousRouterB()

namespaceA = {}
class namespaceA.AmbiguousRouter extends Backbone.Router
  routeHelperId: "nsa"
  routes:
    "namespaced/a" : "namespaced"
nsaRouter = new namespaceA.AmbiguousRouter()

namespaceB = {}
class namespaceB.AmbiguousRouter extends Backbone.Router
  routeHelperId: "nsb"
  routes:
    "namespaced/b" : "namespaced"
nsbRouter = new namespaceB.AmbiguousRouter()


stubber.stub()
Backbone.history.start()

RH = Backbone.RouteHelper
nv = (route) -> router.navigate route, trigger:true

describe "Backbone.RouteHelper", ->

  beforeEach ->
    nv ""

  it "tracks the current route", ->
    route = "i/am/jacks/colon?q=1"
    nv route
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

  it "includes previous query when modifying and query method called", ->
    nv RH.build("jacks").params(jacks: "foot").query(show: "all").route()
    route = RH.modify().params(jacks: "hand").query().route()
    expect(route).toEqual("i/am/jacks/hand?show=all")

  it "doesn't use query when modifying and no call to query method", ->
    nv RH.build("jacks").params(jacks: "foot").query(show: "all").route()
    route = RH.modify().params(jacks: "hand").route()
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

  it "throws an error when cannot find route", ->
    expect(-> RH.build("random string").route())
      .toThrow("No route found for random string")

  it "can disambiguate by router's class name", ->
    rt1 = RH.build("AmbiguousRouterA:ambiguous").route()
    expect(rt1).toEqual("ambiguous/a")
    rt2 = RH.build("AmbiguousRouterB:ambiguous").route()
    expect(rt2).toEqual("ambiguous/b")

  it "can disambiguate by router's routeHelperId", ->
    rt1 = RH.build("nsa:namespaced").route()
    expect(rt1).toEqual("namespaced/a")
    rt2 = RH.build("nsb:namespaced").route()
    expect(rt2).toEqual("namespaced/b")

  it "clears keys with no values", ->
    nv RH.build("root").query(q:"soap",p:"1").route()
    rt = RH.modify().query(p:undefined).route()
    expect(rt).toEqual("?q=soap")

Backbone.history.stop()