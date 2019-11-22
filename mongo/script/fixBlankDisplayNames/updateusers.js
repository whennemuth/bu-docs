var userlist = {
  $or: [
    {
      username: {
        $in:[
          "dhaywood","wrh","mahichy","mukadder","mkousheh","emauro","smorse","cgagnon"
        ]
      }
    },
    {
      name: { $eq:null }
    },
    {
      name: { $exists:false }
    }
  ]
};

var allNamelessUsers = {
  $or: [
    {
      name: { $eq:null }
    },
    {
      name: { $exists:false }
    },
    {
      name: { $eq:"" }
    }
  ]
}

db.users.find(allNamelessUsers).forEach(function(user) {
  // print( "Id: " + user._id );

  function isValue(o) {
    if(o == null) return false;
    if(o === undefined) return false;
    if(!o.toString().trim()) return false;
    return true;
  }

  function Camelize(s) {
    a = s.toLowerCase().split(/\s+/);
    var c = '';
    for(i=0; i<a.length; i++) {
      c += a[i].substr(0,1).toUpperCase();
      c += a[i].substr(1);
      c += ' ';
    }
    return c.trim();
  }

  var name = '';
  if(isValue(user.firstName)) {
    name = Camelize(user.firstName);
  }
  if(isValue(user.lastName)) {
    if(name) name += ' ';
    name += Camelize(user.lastName);
  }
  if(!name && isValue(user.username)) {
    name = user.username.trim();
  }
  if(!name && isValue(user.schoolId)) {
    name = user.schoolId.trim();
  }
  if(name) {
    print(user._id + ': ' + name);
    db.users.update( {_id: user._id }, { $set: { "name": name }});
  }
  else {
    print(user._id + ': ERROR! Cannot build name');
  }
});

