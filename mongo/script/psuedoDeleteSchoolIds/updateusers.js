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
  { schoolId: { $not: /^deleted\-.*/ }}
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
    return isValue(user.schoolId)
    // return isValue(user.username) && isValue(user.email)
  }

  function getDeactivatedValue(user) {
    var prefix = "deleted-" + new Date().toJSON().slice(0,10) + "-";
    return prefix + user.schoolId;
  }

  if(isUpdatable(user)) {
    var schoolId = getDeactivatedValue(user);
    print(user.lowerUsername + ", " + user.schoolId + " > " + schoolId); 
    db.users.update( {_id: user._id }, { $set: {
      "schoolId": schoolId
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