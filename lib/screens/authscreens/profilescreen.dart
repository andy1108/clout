import 'package:clout/models/eventlistview.dart';
import 'package:clout/components/loadingwidget.dart';
import 'package:clout/defs/location.dart';
import 'package:clout/models/profiletopcontainer.dart';
import 'package:clout/defs/user.dart';
import 'package:clout/screens/authentication/signupflowscreens.dart';
import 'package:clout/screens/authscreens/cloutscorescreen.dart';
import 'package:clout/screens/authscreens/editprofilescreen.dart';
import 'package:clout/screens/authscreens/eventdetailscreen.dart';
import 'package:clout/screens/authscreens/favscreen.dart';
import 'package:clout/screens/authscreens/friendsscreen.dart';
import 'package:clout/screens/authscreens/settings.dart';
import 'package:clout/services/db.dart';
import 'package:clout/services/logic.dart';
import 'package:custom_refresh_indicator/custom_refresh_indicator.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_dynamic_links/firebase_dynamic_links.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import 'package:clout/defs/event.dart';

class ProfileScreen extends StatefulWidget {
  AppUser user;
  AppUser curruser;
  bool visit;
  bool iscurruser = false;
  AppLocation curruserlocation;
  FirebaseAnalytics analytics;
  ProfileScreen({
    super.key,
    required this.user,
    required this.curruser,
    required this.visit,
    required this.curruserlocation,
    required this.analytics,
    iscurruser,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  db_conn db = db_conn();
  applogic logic = applogic();

  bool joinedevents = true;
  List<Event> joinedEvents = [];
  List<Event> hostedEvents = [];
  List<AppUser> globalrankedusers = [];
  String friendval = "";

  Future<void> setfriendval() async {
    if (widget.user.plan == "business") {
      if (widget.curruser.followedbusinesses.contains(widget.user.uid)) {
        setState(() {
          friendval = "Unfollow";
        });
      } else {
        setState(() {
          friendval = "Follow";
        });
      }
    } else {
      if (widget.curruser.friends.contains(widget.user.uid)) {
        setState(() {
          friendval = "Remove Friend";
        });
      } else if (widget.curruser.requested.contains(widget.user.uid)) {
        setState(() {
          friendval = "Request Sent";
        });
      } else if (widget.curruser.requestedby.contains(widget.user.uid)) {
        setState(() {
          friendval = "Accept";
        });
      } else if (!widget.curruser.requested.contains(widget.user.uid)) {
        setState(() {
          friendval = "Add Friend";
        });
      }
    }
  }

  Future<void> reportuser() async {
    try {
      await db.reportUser(widget.user);
      logic.displayErrorSnackBar("Reported @${widget.user.username}", context);
      Navigator.pop(context);
    } catch (e) {
      logic.displayErrorSnackBar("Could not report, please try again", context);
    }
  }

  Future<void> blockuser() async {
    try {
      await db.blockUser(widget.curruser.uid, widget.user.uid);
      logic.displayErrorSnackBar(
          "Blocked User! To unblock, please visit Settings.", context);
      Navigator.pop(context);
      Navigator.pop(context);
    } catch (e) {
      logic.displayErrorSnackBar(
          "Could not block user, please try again", context);
    }
  }

  Future<void> refresh() async {
    try {
      await updateuser();
      await updatecurruser();
      await setfriendval();
      await getevents();
    } catch (e) {
      logic.displayErrorSnackBar("Could not refresh", context);
    }
  }

  Future<void> updateuser() async {
    try {
      AppUser updateduser = await db.getUserFromUID(widget.user.uid);
      setState(() {
        widget.user = updateduser;
      });
    } catch (e) {
      logic.displayErrorSnackBar("Could not refresh user", context);
    }
  }

  Future<void> updatecurruser() async {
    try {
      AppUser updateduser = await db.getUserFromUID(widget.curruser.uid);
      setState(() {
        widget.curruser = updateduser;
      });
    } catch (e) {
      logic.displayErrorSnackBar("Could not refresh user", context);
    }
  }

  Future<void> getevents() async {
    if (widget.iscurruser) {
      List<Event> temp1 =
          await db.getProfileScreenJoinedEvents(widget.user, true);
      List<Event> temp2 =
          await db.getProfileScreenHostedEvents(widget.user, true);
      setState(() {
        joinedEvents = temp1;
        hostedEvents = temp2;
      });
    } else {
      List<Event> temp1 =
          await db.getProfileScreenJoinedEvents(widget.user, false);
      List<Event> temp2 =
          await db.getProfileScreenHostedEvents(widget.user, false);
      setState(() {
        joinedEvents = temp1;
        hostedEvents = temp2;
      });
    }
  }

  void editprofile() async {
    await Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => EditProfileScreen(
                  curruser: widget.curruser,
                  analytics: widget.analytics,
                ),
            settings: RouteSettings(name: "EditProfileScreen")));
    refresh();
  }

  void settings() async {
    await Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => SettingsScreen(
                  curruser: widget.curruser,
                  analytics: widget.analytics,
                ),
            settings: RouteSettings(name: "SettingsScreen")));
    refresh();
  }

  void contacts() async {
    await Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => FriendsContactScreen(
                analytics: widget.analytics,
                curruser: widget.curruser,
                loggedin: true),
            settings: RouteSettings(name: "FriendsContactScreen")));
    refresh();
  }

  void favorites() async {
    await Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => FavScreen(
                  curruser: widget.curruser,
                  analytics: widget.analytics,
                  curruserlocation: widget.curruserlocation,
                ),
            settings: RouteSettings(name: "FavoritesScreen")));
    refresh();
  }

  void friendsscreen() async {
    try {
      List<AppUser> friends = await db.getfriendslist(widget.user);
      await Future.delayed(const Duration(milliseconds: 50));
      await Navigator.push(
          context,
          CupertinoPageRoute(
              builder: (_) => FriendsScreen(
                  user: widget.user,
                  curruser: widget.curruser,
                  iscurruser: widget.iscurruser,
                  curruserlocation: widget.curruserlocation,
                  analytics: widget.analytics,
                  friends: friends),
              settings: RouteSettings(name: "FollowerFollowingScreen")));
      refresh();
    } catch (e) {
      logic.displayErrorSnackBar("Could not display followers", context);
    }
  }

  void cloutscreen() async {
    Navigator.push(
        context,
        CupertinoPageRoute(
            builder: (_) => CloutScoreScreen(
                  curruser: widget.curruser,
                  curruserlocation: widget.curruserlocation,
                  analytics: widget.analytics,
                  showleading: true,
                ),
            settings: RouteSettings(name: "CloutScoreScreen")));
  }

  Future<void> friendunfriend() async {
    try {
      await updatecurruser();
      if (widget.curruser.friends.contains(widget.user.uid)) {
        await db.removefriend(widget.curruser.uid, widget.user.uid);
      } else if (widget.curruser.requested.contains(widget.user.uid)) {
        await db.removefriendrequest(widget.curruser.uid, widget.user.uid);
      } else if (widget.curruser.requestedby.contains(widget.user.uid)) {
        await db.acceptfriendrequest(widget.curruser.uid, widget.user.uid);
      } else if (!widget.curruser.requested.contains(widget.user.uid)) {
        await db.sendfriendrequest(widget.curruser.uid, widget.user.uid);
      }
    } catch (e) {
      logic.displayErrorSnackBar("Could not complete action", context);
    } finally {
      refresh();
    }
  }

  Future interactfav(Event event) async {
    try {
      if (widget.curruser.favorites.contains(event.docid)) {
        await widget.analytics.logEvent(name: "rem_from_fav", parameters: {
          "interest": event.interest,
          "inviteonly": event.isinviteonly.toString(),
          "maxparticipants": event.maxparticipants,
          "currentparticipants": event.participants.length
        });
        await db.remFromFav(widget.curruser.uid, event.docid);
      } else {
        await widget.analytics.logEvent(name: "add_to_fav", parameters: {
          "interest": event.interest,
          "inviteonly": event.isinviteonly.toString(),
          "maxparticipants": event.maxparticipants,
          "currentparticipants": event.participants.length
        });
        await db.addToFav(widget.curruser.uid, event.docid);
      }
    } catch (e) {
      logic.displayErrorSnackBar("Could not update favorites", context);
    } finally {
      updatecurruser();
    }
  }

  Future<String> createShareLink() async {
    final dynamicLinkParams = DynamicLinkParameters(
      link: Uri.parse("https://outwithclout.com/#/user/${widget.user.uid}"),
      uriPrefix: "https://outwithclout.page.link",
    );
    final dynamicLink =
        await FirebaseDynamicLinks.instance.buildShortLink(dynamicLinkParams);
    return dynamicLink.shortUrl.toString();
  }

  void shareuser(String text) async {
    final box = context.findRenderObject() as RenderBox?;
    await widget.analytics.logEvent(name: "shared_user", parameters: {
      "iscurruser": widget.iscurruser.toString(),
      "isfrienduser":
          widget.curruser.friends.contains(widget.user.uid).toString(),
      "shared_user_gender": widget.user.gender,
      "sharer_user_gender": widget.curruser.gender
    });
    await Share.share(
      text,
      subject: "Follow @${widget.user.username} on Clout",
      sharePositionOrigin: box!.localToGlobal(Offset.zero) & box.size,
    );
  }

  void refer() async {
    String text =
        "${widget.curruser.fullname} wants you to join them on Clout.\nhttps://outwithclout.com/#/referral/${widget.curruser.uid}";
    final box = context.findRenderObject() as RenderBox?;
    await widget.analytics.logEvent(name: "referred_user", parameters: {});
    await Share.share(
      text,
      subject: "${widget.curruser.fullname} wants you to join them on Clout.",
      sharePositionOrigin: box!.localToGlobal(Offset.zero) & box.size,
    );
  }

  Future<void> navigate(Event event) async {
    try {
      Event chosenEvent = await db.getEventfromDocId(event.docid);
      List<AppUser> participants =
          await db.geteventparticipantslist(chosenEvent);
      await Future.delayed(Duration(milliseconds: 50));
      await Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => EventDetailScreen(
                    event: chosenEvent,
                    curruser: widget.curruser,
                    participants: participants,
                    curruserlocation: widget.curruserlocation,
                    analytics: widget.analytics,
                  ),
              settings: RouteSettings(name: "EventDetailScreen")));
    } catch (e) {
      logic.displayErrorSnackBar("Could not display event", context);
    }
    refresh();
  }

  @override
  void initState() {
    refresh();
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    widget.iscurruser = widget.user.uid == widget.curruser.uid;
    final screenwidth = MediaQuery.of(context).size.width;
    final screenheight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: profilescreenappbar(context, screenheight, screenwidth),
      body: CustomRefreshIndicator(
        onRefresh: refresh,
        builder: (context, child, controller) {
          return LoadingWidget(
            screenheight: screenheight,
            screenwidth: screenwidth,
            controller: controller,
            child: child,
          );
        },
        child: SingleChildScrollView(
          child: SizedBox(
            height: joinedevents
                ? screenheight * 0.4 +
                            (joinedEvents.length *
                                (screenheight * 0.1 + 210.0)) >
                        screenheight
                    ? screenheight * 0.4 +
                        (joinedEvents.length * (screenheight * 0.1 + 210.0)) +
                        50
                    : screenheight
                : screenheight * 0.4 +
                            (hostedEvents.length *
                                (screenheight * 0.1 + 210.0)) >
                        screenheight
                    ? screenheight * 0.4 +
                        (hostedEvents.length * (screenheight * 0.1 + 210.0)) +
                        50
                    : screenheight,
            width: screenwidth,
            child: Column(children: [
              ProfileTopContainer(
                user: widget.user,
                iscurruser: widget.iscurruser,
                curruser: widget.curruser,
                editprofile: editprofile,
                friendsscreen: friendsscreen,
                cloutscreen: cloutscreen,
                friend: friendunfriend,
                refer: refer,
                friendval: friendval,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  InkWell(
                    onTap: () {
                      setState(() {
                        joinedevents = true;
                      });
                    },
                    child: Container(
                      height: screenheight * 0.045,
                      width: screenwidth * 0.5,
                      decoration: BoxDecoration(
                          border: Border(
                              bottom: BorderSide(
                                  color: joinedevents
                                      ? Colors.black
                                      : const Color.fromARGB(
                                          55, 158, 158, 158)),
                              right: const BorderSide(
                                  color: Color.fromARGB(55, 158, 158, 158)))),
                      child: Center(
                          child: Text(
                        "Joined Events",
                        style: TextStyle(
                            fontWeight: joinedevents
                                ? FontWeight.bold
                                : FontWeight.normal),
                      )),
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        joinedevents = false;
                      });
                    },
                    child: Container(
                      height: screenheight * 0.045,
                      width: screenwidth * 0.5,
                      decoration: BoxDecoration(
                          border: Border(
                              bottom: BorderSide(
                                  color: joinedevents
                                      ? const Color.fromARGB(55, 158, 158, 158)
                                      : Colors.black),
                              left: const BorderSide(color: Colors.white))),
                      child: Center(
                          child: Text(
                        "Hosted Events",
                        style: TextStyle(
                            fontWeight: joinedevents
                                ? FontWeight.normal
                                : FontWeight.bold),
                      )),
                    ),
                  )
                ],
              ),
              EventListView(
                eventList: joinedevents ? joinedEvents : hostedEvents,
                onTap: navigate,
                scrollable: false,
                leftpadding: 18.0,
                curruser: widget.curruser,
                interactfav: interactfav,
                screenheight: screenheight,
                screenwidth: screenwidth,
              ),
            ]),
          ),
        ),
      ),
    );
  }

  AppBar profilescreenappbar(
      BuildContext context, double screenheight, double screenwidth) {
    return AppBar(
      leading: widget.visit
          ? GestureDetector(
              onTap: () {
                Navigator.pop(context);
              },
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Icon(
                  Icons.arrow_back_ios,
                  color: Theme.of(context).primaryColor,
                ),
              ),
            )
          : const SizedBox(
              width: 0,
              height: 0,
            ),
      centerTitle: true,
      title: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          widget.user.username,
          textScaler: const TextScaler.linear(1.0),
          style: TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.bold,
              fontSize: widget.iscurruser ? 30 : 20),
        ),
      ),
      backgroundColor: Colors.white,
      shadowColor: Colors.white,
      elevation: 0.0,
      automaticallyImplyLeading: widget.visit ? true : false,
      actions: widget.iscurruser
          ? [
              GestureDetector(
                  onTap: () async {
                    String link = await createShareLink();
                    String text =
                        "Follow @${widget.user.username} on Clout\n\n$link";
                    shareuser(text);
                  },
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(0.0, 0.0, 8.0, 0.0),
                    child: const Icon(Icons.ios_share, color: Colors.black),
                  )),
              GestureDetector(
                onTap: () {
                  showthreedotbottomsheet(context, screenheight, screenwidth);
                },
                child: const Padding(
                  padding: EdgeInsets.fromLTRB(0, 0, 8, 0),
                  child: Icon(
                    Icons.more_vert_outlined,
                    color: Colors.black,
                  ),
                ),
              ),
            ]
          : [
              GestureDetector(
                  onTap: () async {
                    String link = await createShareLink();
                    String text =
                        "Follow @${widget.user.username} on Clout\n\n$link";
                    shareuser(text);
                  },
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(0.0, 0.0, 8.0, 0.0),
                    child: const Icon(Icons.ios_share, color: Colors.black),
                  )),
              GestureDetector(
                onTap: () async {
                  showModalBottomSheet(
                      backgroundColor: Colors.white,
                      context: context,
                      builder: (BuildContext context) {
                        return SizedBox(
                          height: screenheight * 0.16,
                          width: screenwidth,
                          child: Padding(
                            padding:
                                const EdgeInsets.fromLTRB(16.0, 8.0, 0.0, 0.0),
                            child: Column(children: [
                              Container(
                                width: 40,
                                height: 8,
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.transparent),
                                  borderRadius: BorderRadius.circular(10),
                                  color: const Color.fromARGB(60, 0, 0, 0),
                                ),
                              ),
                              SizedBox(
                                height: screenheight * 0.01,
                              ),
                              GestureDetector(
                                onTap: () async {
                                  await reportuser();
                                },
                                child: Row(
                                  children: [
                                    Icon(Icons.flag_circle, size: 30),
                                    SizedBox(
                                      width: 6,
                                    ),
                                    Text(
                                      "Report ${widget.user.fullname}",
                                      style: TextStyle(fontSize: 20),
                                    )
                                  ],
                                ),
                              ),
                              SizedBox(
                                height: screenheight * 0.02,
                              ),
                              GestureDetector(
                                onTap: () async {
                                  await blockuser();
                                },
                                child: Row(
                                  children: [
                                    Icon(Icons.block, size: 30),
                                    SizedBox(
                                      width: 6,
                                    ),
                                    Text(
                                      "Block ${widget.user.fullname}",
                                      style: TextStyle(fontSize: 20),
                                    )
                                  ],
                                ),
                              ),
                            ]),
                          ),
                        );
                      });
                },
                child: const Padding(
                  padding: EdgeInsets.fromLTRB(0, 0, 8, 0),
                  child: Icon(
                    Icons.flag_outlined,
                    color: Colors.black,
                  ),
                ),
              ),
            ],
      shape: const Border(
          bottom: BorderSide(color: Color.fromARGB(55, 158, 158, 158))),
    );
  }

  Future<dynamic> showthreedotbottomsheet(
      BuildContext context, double screenheight, double screenwidth) {
    return showModalBottomSheet(
        backgroundColor: Colors.white,
        context: context,
        builder: (BuildContext context) {
          return SizedBox(
            height: screenheight * 0.15,
            width: screenwidth,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16.0, 8.0, 0.0, 0.0),
              child: Column(children: [
                Container(
                  width: 40,
                  height: 8,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.transparent),
                    borderRadius: BorderRadius.circular(10),
                    color: const Color.fromARGB(60, 0, 0, 0),
                  ),
                ),
                SizedBox(
                  height: screenheight * 0.01,
                ),
                GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                    settings();
                  },
                  child: const Row(
                    children: [
                      Icon(Icons.settings, size: 30),
                      SizedBox(
                        width: 6,
                      ),
                      Text(
                        "Settings",
                        style: TextStyle(fontSize: 20),
                      )
                    ],
                  ),
                ),
                SizedBox(
                  height: screenheight * 0.01,
                ),
                GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                    contacts();
                  },
                  child: const Row(
                    children: [
                      Icon(CupertinoIcons.person_add_solid, size: 30),
                      SizedBox(
                        width: 6,
                      ),
                      Text(
                        "Friend suggestions",
                        style: TextStyle(fontSize: 20),
                      )
                    ],
                  ),
                ),
              ]),
            ),
          );
        });
  }
}
