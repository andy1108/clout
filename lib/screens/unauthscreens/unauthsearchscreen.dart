import 'dart:io';
import 'dart:typed_data';

import 'package:clout/defs/location.dart';
import 'package:clout/models/searchgridview.dart';
import 'package:clout/defs/user.dart';
import 'package:clout/screens/unauthscreens/unauthinterestsearchscreen.dart';
import 'package:clout/services/db.dart';
import 'package:clout/services/logic.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
import 'package:clout/defs/event.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';
import 'dart:ui' as ui;

class UnAuthSearchScreen extends StatefulWidget {
  UnAuthSearchScreen(
      {super.key, required this.curruserlocation, required this.analytics});
  AppLocation curruserlocation;
  FirebaseAnalytics analytics;
  @override
  State<UnAuthSearchScreen> createState() => _UnAuthSearchScreenState();
}

class _UnAuthSearchScreenState extends State<UnAuthSearchScreen> {
  GoogleMapController? mapController;
  db_conn db = db_conn();
  applogic logic = applogic();
  bool showbutton = false;
  CameraPosition? cameraposition;
  FocusNode focusNode = FocusNode();
  TextEditingController searchcontroller = TextEditingController();
  Color suffixiconcolor = Colors.white;
  List interests = [
    "Sports",
    "Nature",
    "Music",
    "Dance",
    "Movies",
    "Acting",
    "Singing",
    "Drinking",
    "Food",
    "Art",
    "Animals",
    "Fashion",
    "Cooking",
    "Culture",
    "Travel",
    "Games",
    "Studying",
    "Chilling"
  ];

  Map<MarkerId, Marker> markers = <MarkerId, Marker>{};

  void gotointerestsearchscreen(
      String interest, List<Event> interesteventlist) {
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => UnAuthInterestSearchScreen(
                  interest: interest,
                  events: interesteventlist,
                  curruserlocation: widget.curruserlocation,
                  analytics: widget.analytics,
                ),
            settings: RouteSettings(name: "UnAuthInterestSearchScreen")));
  }

  Future<BitmapDescriptor> convertImageFileToCustomBitmapDescriptor(
    File imageFile, {
    int size = 150,
    bool addBorder = true,
    Color borderColor = const Color.fromARGB(255, 255, 48, 117),
    double borderSize = 10,
    bool event = false,
  }) async {
    final ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(pictureRecorder);
    final Paint paint = Paint()..color;
    final double radius = size / 2;
    event ? size = 200 : null;
    event ? borderSize = 20 : null;
    //make canvas clip path to prevent image drawing over the circle
    final Path clipPath = Path();

    clipPath.addRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.toDouble(), size.toDouble()),
        event ? const Radius.circular(10) : const Radius.circular(200)));

    canvas.clipPath(clipPath);

    //paintImage
    final Uint8List imageUint8List = await imageFile.readAsBytes();
    final ui.Codec codec = await ui.instantiateImageCodec(imageUint8List);
    final ui.FrameInfo imageFI = await codec.getNextFrame();
    paintImage(
        canvas: canvas,
        rect: Rect.fromLTWH(0, 0, size.toDouble(), size.toDouble()),
        image: imageFI.image,
        fit: BoxFit.cover);

    if (addBorder) {
      //draw Border
      paint.color = event ? Colors.white : borderColor;
      paint.style = PaintingStyle.stroke;
      paint.strokeWidth = borderSize;
      event
          ? canvas.drawRRect(
              RRect.fromRectAndRadius(
                  Rect.fromLTWH(0, 0, size.toDouble(), size.toDouble()),
                  const Radius.circular(10)),
              paint)
          : canvas.drawCircle(Offset(radius, radius), radius, paint);
    }

    //convert canvas as PNG bytes
    final _image = await pictureRecorder
        .endRecording()
        .toImage(size.toInt(), size.toInt());
    final data = await _image.toByteData(format: ui.ImageByteFormat.png);

    //convert PNG bytes as BitmapDescriptor
    return BitmapDescriptor.fromBytes(data!.buffer.asUint8List());
  }

  void setmarkers(
      List<AppUser> users, List<AppUser> businesses, List<Event> events) async {
    Map<MarkerId, Marker> markerdict = {};

    for (int i = 0; i < events.length; i++) {
      final File markerImageFile =
          await DefaultCacheManager().getSingleFile(events[i].image);
      BitmapDescriptor bmd = await convertImageFileToCustomBitmapDescriptor(
          markerImageFile,
          event: true);

      Marker marker = Marker(
        markerId: MarkerId(events[i].docid),
        draggable: true,
        position: LatLng(
            events[i].lat,
            events[i]
                .lng), //With this parameter you automatically obtain latitude and longitude
        infoWindow: InfoWindow.noText,
        onTap: () async {
          Event event = await db.getEventfromDocId(events[i].docid);
          List<AppUser> participants = await db.geteventparticipantslist(event);
          logic.gounautheventdetailscreen(widget.analytics,
              widget.curruserlocation, events[i], participants, context);
        },
        icon: bmd,
      );
      markerdict[MarkerId(events[i].docid)] = marker;
    }

    for (int i = 0; i < businesses.length; i++) {
      final File markerImageFile =
          await DefaultCacheManager().getSingleFile(businesses[i].pfpurl);
      BitmapDescriptor bmd =
          await convertImageFileToCustomBitmapDescriptor(markerImageFile);

      Marker marker = Marker(
          markerId: MarkerId(businesses[i].uid),
          draggable: true,
          position: LatLng(
              businesses[i].lastknownlat,
              businesses[i]
                  .lastknownlng), //With this parameter you automatically obtain latitude and longitude
          icon: bmd,
          infoWindow: InfoWindow.noText,
          onTap: () async {});
      markerdict[MarkerId(businesses[i].uid)] = marker;
    }

    setState(() {
      markers = markerdict;
    });
  }

  Future<void> searchnav(String interest) async {
    try {
      List<Event> interesteventlist = [];
      interesteventlist = await db.UnAuthgetLngLatEventsByInterest(
        widget.curruserlocation.center[0],
        widget.curruserlocation.center[1],
        interest,
      );
      gotointerestsearchscreen(interest, interesteventlist);
      //print(interesteventlist);
    } catch (e) {
      logic.displayErrorSnackBar("Could not display events", context);
    }
  }

  @override
  Widget build(BuildContext context) {
    double screenheight = MediaQuery.of(context).size.height;
    double screenwidth = MediaQuery.of(context).size.width;

    return Scaffold(
        backgroundColor: Colors.white,
        body: SlidingUpPanel(
          minHeight: 130,
          maxHeight: screenheight * 0.6,
          defaultPanelState: PanelState.OPEN,
          backdropColor: Theme.of(context).primaryColor,
          parallaxEnabled: true,
          parallaxOffset: 0.2,
          borderRadius: const BorderRadius.only(
              topRight: Radius.circular(20), topLeft: Radius.circular(20)),
          panel: Column(
            children: [
              const SizedBox(
                height: 15,
              ),
              Container(
                width: 40,
                height: 8,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.transparent),
                  borderRadius: BorderRadius.circular(10),
                  color: const Color.fromARGB(60, 0, 0, 0),
                ),
              ),
              const SizedBox(
                height: 5,
              ),
              SearchGridView(
                interests: interests,
                onTap: searchnav,
              ),
            ],
          ),
          body: Stack(
            children: [
              GoogleMap(
                //Map widget from google_maps_flutter package
                myLocationButtonEnabled: false,
                markers: Set<Marker>.of(markers.values),
                zoomGesturesEnabled: true, //enable Zoom in, out on map
                initialCameraPosition: CameraPosition(
                  //innital position in map
                  target: LatLng(widget.curruserlocation.center[1],
                      widget.curruserlocation.center[0]), //initial position
                  zoom: 12.0, //initial zoom level
                ),

                mapType: MapType.normal, //map type

                onMapCreated: (controller) async {
                  //method called when map is created
                  try {
                    List<Event> events = await db.unauthretrieveeventsformap(
                        widget.curruserlocation.center[1],
                        widget.curruserlocation.center[0]);
                    List<AppUser> businesses =
                        await db.retrievebusinessesformap(
                            widget.curruserlocation.center[1],
                            widget.curruserlocation.center[0]);
                    setmarkers(<AppUser>[], businesses, events);

                    setState(() {
                      mapController = controller;
                      showbutton = false;
                    });
                  } catch (e) {
                    logic.displayErrorSnackBar("Error loading map", context);
                  }
                },
                onCameraMove: (position) {
                  setState(() {
                    cameraposition = position;
                    showbutton = true;
                  });
                },
              ),
              showbutton
                  ? Align(
                      alignment: Alignment.bottomCenter,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(0, 0, 0, 150),
                        child: GestureDetector(
                          onTap: () async {
                            try {
                              List<Event> events =
                                  await db.unauthretrieveeventsformap(
                                cameraposition!.target.latitude,
                                cameraposition!.target.longitude,
                              );
                              List<AppUser> businesses =
                                  await db.retrievebusinessesformap(
                                      widget.curruserlocation.center[1],
                                      widget.curruserlocation.center[0]);
                              setmarkers(<AppUser>[], businesses, events);
                              setState(() {
                                showbutton = false;
                              });
                            } catch (e) {
                              logic.displayErrorSnackBar(
                                  "Error loading map", context);
                            }
                          },
                          child: Container(
                            width: screenwidth * 0.4,
                            height: screenheight * 0.05,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              color: Theme.of(context).primaryColor,
                            ),
                            child: const Center(
                              child: Text(
                                "Search Area",
                                style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                        ),
                      ),
                    )
                  : Container(),
            ],
          ),
        ));
  }
}
