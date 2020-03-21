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

var allInactiveUsers = { $and: [
  {
    $or: [
      {
        active: { $eq:null }
      },
      {
        active: { $exists:false }
      },
      {
        active: { $eq:false }
      },
      {
        active: { $eq:"false" }
      }
    ]
  },
  { lowerUsername: { $not: /^deleted\-.*/ }}
]}

var counter=0;
var failures=[];
db.users.find(allInactiveUsers).forEach(function(user) {
  //print( "Id: " + user._id );

  function isValue(o) {
    if(o == null) return false;
    if(o === undefined) return false;
    if(!o.toString().trim()) return false;
    return true;
  }

  function isUpdatable(user) {
    return isValue(user.lowerUsername)
    // return isValue(user.username) && isValue(user.email)
  }

  function getDeactivatedValue(user) {
    var prefix = "deleted-" + new Date().toJSON().slice(0,10) + "-";
    return {
      username: prefix + user.username,
      lowerUsername: prefix + user.lowerUsername.toLowerCase(),
      email: prefix + user.email
    }
  }

  if(isUpdatable(user)) {
    var updates = getDeactivatedValue(user);
    print(updates.lowerUsername);
  //   db.users.update( {_id: user._id }, { $set: {
  //     "username": updates.username,
  //     "email": updates.email
  //  }});
    db.users.update( {_id: user._id }, { $set: {
      "lowerUsername": updates.lowerUsername
    }});
    counter++
  }
  else {
    failures.push(user._id);
  }

});

print("--------------------------");
print("    PROCESSED " + counter + " USERS");
print("--------------------------");

if(failures.length > 0) {
  print("--------------------------");
  print("    FAILED: ");
  for(var i=0; i<failures.length; i++) {
    print("    " + failures[i]);
  }
  print("--------------------------");
}