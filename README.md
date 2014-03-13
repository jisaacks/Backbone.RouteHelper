# Backbone.RouteHelper

Build and manipulate Backbone routes. _Requires Backbone.js version 1.1.1 or above._

### API

[Wiki](https://github.com/emcien/Backbone.RouteHelper/wiki/API)

### Usage

Define your Backbone routes like you normally would:

```javascript
var MyRouter = Backbone.Router.extend({

  routes: {
    "about"                         : "about"
    "user/:user_id/comments"        : "comments"
    "user/:user_id/posts"           : "posts"
    "user/:user_id/posts/:post_id"  : "post"
  }

});
```
The names of the callbacks become the route names you would use when building a route:

```javascript
var route = Backbone.RouteHelper.build("comments").params({user_id: 17}).route();
console.log(route); // user/17/comments
```

To update a param on the current route:

```javascript
// current route is user/17/comments
var route = Backbone.RouteHelper.modify().params({user_id: 21}).route();
console.log(route); // user/21/comments
```

To use the current params on a new route:

```javascript
// current route is user/21/comments
var route = Backbone.RouteHelper.modify("posts").route();
console.log(route); // user/21/posts
```

#### Using Queries

Setting:

```javascript
var route = Backbone.RouteHelper.build("comments")
  .params({user_id: 1})
  .query({page: 2})
  .route();
console.log(route); // user/1/comments?page=2
```

Updating:

```javascript
// current route is user/1/comments?page=2
var route = Backbone.RouteHelper.modify().query({page: 3}).route();
console.log(route); // user/1/comments?page=3
```

**A note on query parsing:** By default Backbone.RouteHelper expects a global to be present called **qs**, which is an instance of [node-querystring](https://github.com/visionmedia/node-querystring). This repo includes a build of that project called `qs.js` all you would need to do is include that script before the route helper script. Alternatively, you can use your own query parser by overriding a couple methods: 

```javascript
_.extend(Backbone.RouteHelper.prototype, {
  _parseQuery: function (str) { return myParser.parse(str); },
  _buildQuery: function (obj) { return myParser.stringify(obj); }
});
```

**All of the above examples can be mixed to give a lot of flexibility in how you build your routes**

For example:

```javascript
// current route is user/2/comments?page=4
var route = Backbone.RouteHelper.modify("post")
  .params({post_id: 7})
  .build()
  .query({show_replies: true})
  .route();
console.log(route); // user/2/posts/7?show_replies=true
```

### Installation

Include the **qs.js** and **backbone.route_helper.js** scripts loacated under **lib** into your project respectively. Alternatvely you can skip **qs.js** and use your own parser. [See above](https://github.com/emcien/Backbone.RouteHelper#using-queries) for details on how.

**warning:** This relies on Backbone.js version 1.1.1 or above.

### Testing

__Install required packages:__

* Install npm dev packages: `npm install --dev`
* Install [*coffee-script*](https://github.com/jashkenas/coffee-script): `npm install -g coffee-script`
* Install [*node-jasmine*](https://github.com/mhevery/jasmine-node): `npm install -g node-jasmine`

__Now run the the spec:__

`jasmine-node --coffee spec/`
