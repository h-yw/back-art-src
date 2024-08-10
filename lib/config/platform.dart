import 'dart:ui';

import 'package:flutter/cupertino.dart';

Map<String, List<Map<String,dynamic>>> platformSize = {
  "Facebook": [
    {"name": "Square", "size": const Size(1200, 1200), "ratio": "1:1"},
    {"name": "Landscape", "size": const Size(1200, 630), "ratio": "1.905:1"},
    {"name": "Portrait", "size": const Size(630, 1200), "ratio": "0.525:1"},
    {"name": "Profile", "size": const Size(320, 320), "ratio": "1:1"},
    {"name": "Cover Photo", "size": const Size(1200, 628), "ratio": "2:1"},
    {"name": "Stories", "size": const Size(1080, 1920), "ratio": "9:16"},
    {"name": "Ad:All	", "size": const Size(1080, 1080), "ratio": "1:1"}
  ],
  "Instagram": [
    {"name": "Square", "size": const Size(1200, 1200), "ratio": "1:1"},
    {"name": "Landscape", "size": const Size(1200, 630), "ratio": "1.905:1"},
    {"name": "Portrait", "size": const Size(630, 1200), "ratio": "0.525:1"},
    {"name": "Profile", "size": const Size(320, 320), "ratio": "1:1"},
    {"name": "Stories", "size": const Size(1080, 1920), "ratio": "9:16"},
  ],
  "X(Twitter)": [
    {"name": "Square", "size": const Size(1200, 1200), "ratio": "1:1"},
    {"name": "Landscape", "size": const Size(1200, 900), "ratio": "4:3"},
    {"name": "Portrait", "size": const Size(900, 1200), "ratio": "3:4"},
    {"name": "Profile", "size": const Size(400, 400), "ratio": "1:1"},
    {"name": "Cover Photo", "size": const Size(1500, 500), "ratio": "3:1"},
    {"name": "In-Steam Photos", "size": const Size(1600, 900), "ratio": "16:9"},
    {"name": "Card Image", "size": const Size(120, 120), "ratio": "1:1"},
    {"name": "Ad:Tweets", "size": const Size(600, 335), "ratio": "1.79:1"},
    {
      "name": "Ad:Web Card Image",
      "size": const Size(800, 418),
      "ratio": "1.91:9"
    },
    {"name": "Ad:App Card Image", "size": const Size(800, 800), "ratio": "1:1"}
  ],
  "Pinterest": [
    {"name": "Square", "size": const Size(1000, 1000), "ratio": "1:1"},
    {
      "name": "Static and Ad Specs",
      "size": const Size(1000, 1500),
      "ratio": "2:3"
    },
    {"name": "Idea Pin", "size": const Size(1080, 1920), "ratio": "9:16"},
    {"name": "Square Pin", "size": const Size(1000, 1000), "ratio": "1:1"},
    {"name": "Long Pin", "size": const Size(1000, 2100), "ratio": "1:2.1"},
    {"name": "Infographic Pin", "size": const Size(1000, 3000), "ratio": "1:3"},
    {"name": "Ad:All	", "size": const Size(1000, 1500), "ratio": "2:3"}
  ],
  "LinkedIn": [
    {"name": "Landscape", "size": const Size(1200, 627), "ratio": "1.914:1"},
    {"name": "Portrait", "size": const Size(627, 1200), "ratio": "0.5225:1"},
    {"name": "Blog Post", "size": const Size(1080, 1080), "ratio": "1:1"},
    {"name": "Company Logo", "size": const Size(300, 300), "ratio": "1:1"},
    {"name": "Company Square Logo", "size": const Size(60, 60), "ratio": "1:1"},
    {
      "name": "Company Cover Image",
      "size": const Size(1128, 191),
      "ratio": "6:1"
    },
    {
      "name": "Life Tab Main Image",
      "size": const Size(1128, 376),
      "ratio": "3:1"
    },
    {
      "name": "Lift Tab Modules Image",
      "size": const Size(502, 282),
      "ratio": "1.78:1"
    },
    {
      "name": "Lift Tab Photo Image",
      "size": const Size(900, 600),
      "ratio": "3:2"
    }
  ],
};

Map<String, List<dynamic>> platformSizeChina = {
  "小红书": [
    {"name": "Square", "size": const Size(1080, 1080), "ratio": "1:1"},
    {"name": "Landscape", "size": const Size(1200, 900), "ratio": "4:3"},
    {"name": "Portrait", "size": const Size(900, 1200), "ratio": "3:4"},
    {"name": "Profile", "size": const Size(400, 400), "ratio": "1:1"},
    {"name": "Cover Landscape", "size": const Size(800, 600), "ratio": "4:3"},
    {"name": "Cover Portrait", "size": const Size(1242, 1660), "ratio": "3:4"},
    {"name": "Background", "size": const Size(1000, 800), "ratio": "10:8"}
  ],
  "微博": [
    {"name": "Normal", "size": const Size(980, 900), "ratio": "1.08:1"},
    {"name": "Long", "size": const Size(800, 2000), "ratio": "0.4:1"},
    {"name": "Profile", "size": const Size(180, 180), "ratio": "1:1"},
    {"name": "Home Cover", "size": const Size(980, 300), "ratio": "3:1"},
    {"name": "Story Cover", "size": const Size(980, 560), "ratio": "1.75:1"},
    {"name": "Focus Cover", "size": const Size(540, 260), "ratio": "2:1"}
  ],
  "微信公众号": [
    {"name": "Profile", "size": const Size(240, 240), "ratio": "1:1"},
    {"name": "Home Cover", "size": const Size(900, 383), "ratio": "2.35:1"},
    {"name": "Home Logo", "size": const Size(200, 200), "ratio": "1:1"},
    {
      "name": "Video Cover Landscape",
      "size": const Size(1080, 608),
      "ratio": "16:9"
    },
    {
      "name": "Video Cover Portrait",
      "size": const Size(1080, 1260),
      "ratio": "6:7"
    },
    {
      "name": "Content Welcome Image",
      "size": const Size(900, 500),
      "ratio": "9:5"
    },
    {"name": "QRCode Card", "size": const Size(600, 600), "ratio": "1:1"}
  ]
};
