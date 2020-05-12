import 'package:http/http.dart';

final successMeResponse = Response("""
{
  "signedIn":true,
  "id":40839,
  "ownerId":40839,
  "name":"MaxMax",
  "username":"maxmax",
  "avatar":null,
  "isAdmin":false,
  "isPaid":false,
  "notificationCount":5,
  "verified":true
}
""", 200);

final failureMeResponse = Response('{"signedIn":false}', 200);

final successTeamsResponse = Response("""
[{
    "ownerId": 41545,
    "name": "Team Titans",
    "username": "team_titans",
    "avatar": "https://cdn.2dimensions.com/avatars/krypton-41545-b131305f-6aba-4fe5-b797-a10035143fa0",
    "permission": "Owner"
}, {
    "ownerId": 41576,
    "name": "Avengers",
    "username": "avengers_101",
    "avatar": null,
    "permission": "Member"
}]
""", 200);

final successSearchResponse = Response("""
[{
    "n": "Mike",
    "i": 40981,
    "l": null,
    "a": null
}, {
    "n": "pollux",
    "i": 40836,
    "l": "Guido Rosso",
    "a": "https://cdn.2dimensions.com/avatars/40836-1-1570241275-krypton"
}, {
    "n": "castor",
    "i": 16479,
    "l": "Luigi Rosso",
    "a": "https://cdn.2dimensions.com/avatars/16479-1-1547266294-krypton"
}]""", 200);

final successFoldersResponse = Response("""
{
    "folders": [{
        "id": 0,
        "name": "Your Files",
        "parent": null,
        "order": 0
    }, {
        "id": 19,
        "name": "New Folder",
        "parent": 1,
        "order": 0
    }, {
        "id": 18,
        "name": "New Folder",
        "parent": 0,
        "order": 0
    }, {
        "id": 1,
        "name": "Deleted Files",
        "parent": null,
        "order": 1
    }],
    "sortOptions": [{
        "name": "Recent",
        "route": "/api/my/files/recent/"
    }, {
        "name": "Oldest",
        "route": "/api/my/files/oldest/"
    }, {
        "name": "A - Z",
        "route": "/api/my/files/a-z/"
    }, {
        "name": "Z - A",
        "route": "/api/my/files/z-a/"
    }]
}
""", 200);

final successTeamFoldersResponse = Response("""
{
    "folders": [{
        "id": 1,
        "name": "Your Files",
        "parent": null,
        "order": 0,
        "project_name": "default",
        "project_owner_id": 3
    }, {
        "id": 0,
        "name": "Deleted Files",
        "parent": null,
        "order": 1,
        "project_name": "default",
        "project_owner_id": 3
    }],
    "sortOptions": [{
        "name": "Recent",
        "route": "/api/teams/40857/folders/"
    }, {
        "name": "Oldest",
        "route": "/api/teams/40857/folders/"
    }, {
        "name": "A - Z",
        "route": "/api/teams/40857/folders/"
    }, {
        "name": "Z - A",
        "route": "/api/teams/40857/folders/"
    }]
}
""", 200);

final successFilesResponse = Response("""
[
11,
12,
13,
14,
15,
16,
17,
18,
19,
20,
3,
21,
22,
23,
24,
25
]""", 200);

final successFileDetailsResponse = Response("""
{
  "cdn": {
    "base": "http://foofo.com/",
    "params": "?param"
  },
  "files":[ {
    "id":1,
    "oid":1,
    "name":"New File",
    "preview":"<preview>"
  }, {
    "id":2,
    "oid":1,
    "name":"New File 2",
    "preview":"<preview2>"
  }, {
    "id":3,
    "oid":1,
    "name":"New File 3",
    "preview":"<preview3>"
  }]
}
""", 200);

final successTeamMembersResponse = Response("""
[{
    "ownerId":40836,
    "username":"pollux",
    "name":"Guido Rosso",
    "status":"complete",
    "permission":"Member",
    "avatar":null
}]
""", 200);

final myFoldersResponse = """
{
  "folders": [
    {
      "id": 1,
      "name": "Your Files",
      "parent": null,
      "order": 0
    },
    {
      "id": 2,
      "name": "New Folder",
      "parent": 1,
      "order": 0
    },
    {
      "id": 3,
      "name": "New Folder",
      "parent": 2,
      "order": 0
    },
    {
      "id": 4,
      "name": "New Folder",
      "parent": 2,
      "order": 0
    },
    {
      "id": 0,
      "name": "Deleted Files",
      "parent": null,
      "order": 1
    }
  ],
  "sortOptions": [
    {
      "name": "Recent",
      "route": "/api/my/files/recent/"
    },
    {
      "name": "Oldest",
      "route": "/api/my/files/oldest/"
    },
    {
      "name": "A - Z",
      "route": "/api/my/files/a-z/"
    },
    {
      "name": "Z - A",
      "route": "/api/my/files/z-a/"
    }
  ]
}
""";

final myFilesResponse = '[1,2]';

final myFilesDetailsResponse = """
{
  "cdn": {
    "base": "https://base.rive.app/",
    "params": "riveCDNparams"
  },
  "files": [
    {
      "id": 1,
      "oid": 12345,
      "name": "First file"
    },
    {
      "id": 2,
      "oid": 12345,
      "name": "Prova"
    }
  ]
}
""";
