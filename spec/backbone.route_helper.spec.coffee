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

  it "knows which ambiguous route to use when modifying current", ->
    nv RH.build("nsa:namespaced").route()
    rt1 = RH.modify().query(q:1).route()
    expect(rt1).toEqual("namespaced/a?q=1")
    
    nv RH.build("nsb:namespaced").route()
    rt2 = RH.modify().query(q:1).route()
    expect(rt2).toEqual("namespaced/b?q=1")

    nv RH.build("AmbiguousRouterA:ambiguous").route()
    rt3 = RH.modify().query(q:1).route()
    expect(rt3).toEqual("ambiguous/a?q=1")

    nv RH.build("AmbiguousRouterB:ambiguous").route()
    rt4 = RH.modify().query(q:1).route()
    expect(rt4).toEqual("ambiguous/b?q=1")

  it "clears keys with no values", ->
    nv RH.build("root").query(q:"soap",p:"1").route()
    rt = RH.modify().query(p:undefined).route()
    expect(rt).toEqual("?q=soap")

  it "doesn't break when a regex route is triggered", ->
    router.route(/seenit\d+times/,"regex")
    nv "seenit12times"
    expect(Backbone.history.fragment).toEqual("seenit12times")

  it "throws an error when constructing a route without a template", ->
    router.route(/watchedit\d+times/,"regex")
    nv "watchedit21times"
    expect(-> RH.route()).toThrow("No template found for #{/watchedit\d+times/}")

  it "doesn't break when an unnamed route is triggered", ->
    router.route "no/name", -> null
    nv "no/name"
    expect(RH.route()).toEqual("no/name")

  it "can navigate", ->
    RH.build("jacks").params(jacks: "lack_of_surprise").navigate(true)
    expect(RH.route()).toEqual("i/am/jacks/lack_of_surprise")

  it "builds route when coerced into string", ->
    rt = RH.build("jacks").params(jacks: "cold_sweat")
    expect("#{rt}").toEqual(rt.route())

  it "can be passed to router.navigate without being converted to a string", ->
    nv RH.build("jacks").params(jacks: "revenge")
    expect(RH.route()).toEqual("i/am/jacks/revenge")

  it "can omit keys from query string", ->
    nv RH.build("jacks").params(jacks: "omition").query(a:"one", b:"two")
    RH.omit("a").navigate(true)
    expect(RH.route()).toEqual("i/am/jacks/omition?b=two")

  it "can pick keys from query string", ->
    nv RH.build("jacks").params(jacks: "pick").query(a:"one", b:"two")
    RH.pick("a").navigate(true)
    expect(RH.route()).toEqual("i/am/jacks/pick?a=one")

Backbone.history.stop()