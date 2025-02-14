import 'package:clout/defs/event.dart';
import 'package:clout/defs/location.dart';
import 'package:clout/components/primarybutton.dart';
import 'package:clout/models/searchlocation.dart';
import 'package:clout/screens/authentication/authscreen.dart';
import 'package:clout/services/db.dart';
import 'package:clout/services/logic.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter_datetime_picker/flutter_datetime_picker.dart' as dp;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';

import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import 'dart:io';
import 'package:flutter_image_compress/flutter_image_compress.dart';

class UnAuthCreateEventScreen extends StatefulWidget {
  UnAuthCreateEventScreen(
      {super.key,
      required this.allowbackarrow,
      required this.startinterest,
      required this.analytics});

  bool allowbackarrow;
  String startinterest;
  FirebaseAnalytics analytics;

  @override
  State<UnAuthCreateEventScreen> createState() =>
      _UnAuthCreateEventScreenState();
}

class _UnAuthCreateEventScreenState extends State<UnAuthCreateEventScreen> {
  Event event = Event(
      title: "",
      description: "",
      interest: "",
      image: "",
      address: "",
      country: "",
      city: [],
      host: "",
      hostdocid: "",
      maxparticipants: 0,
      participants: [],
      datetime: DateTime(0, 0, 0),
      docid: "",
      lat: 0,
      lng: 0,
      chatid: "",
      isinviteonly: false,
      presentparticipants: [],
      customimage: false,
      showparticipants: true,
      showlocation: true,
      fee: 0,
      paid: false,
      currency: '');

  List<String> allinterests = [
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

  db_conn db = db_conn();
  applogic logic = applogic();
  late String selectedinterest;
  ImagePicker picker = ImagePicker();
  var imagepath;
  var compressedimgpath;
  TextEditingController titlecontroller = TextEditingController();
  TextEditingController desccontroller = TextEditingController();
  TextEditingController maxpartcontroller = TextEditingController();
  DateTime eventdate = DateTime(0, 0, 0);
  AppLocation chosenLocation =
      AppLocation(address: "", city: "", country: "", center: [0.0, 0.0]);
  bool emptylocation = true;
  bool buttonpressed = false;
  bool isinviteonly = false;
  GoogleMapController? mapController;
  Map<MarkerId, Marker> markers = <MarkerId, Marker>{};
  List LatLngs = [];
  bool authbuttonpressed = false;
  bool hideparticipants = false;

  Future _addMarker(LatLng latlang) async {
    setState(() {
      final MarkerId markerId = MarkerId("chosenlocation");
      Marker marker = Marker(
        markerId: markerId,
        draggable: true,
        position:
            latlang, //With this parameter you automatically obtain latitude and longitude
        infoWindow: const InfoWindow(
          title: "Chosen Location",
        ),
        icon: BitmapDescriptor.defaultMarker,
      );

      markers[markerId] = marker;
    });

    //This is optional, it will zoom when the marker has been created
  }

  Future<XFile> CompressAndGetFile(File file) async {
    try {
      final filePath = file.absolute.path;
      final lastIndex = filePath.lastIndexOf(".");
      final splitted = filePath.substring(0, (lastIndex));
      final outPath = "${splitted}_out${filePath.substring(lastIndex)}";
      var result = await FlutterImageCompress.compressAndGetFile(
        filePath,
        outPath,
        quality: 5,
      );

      //print(file.lengthSync());
      //print(result!.lengthSync());

      return result!;
    } catch (e) {
      throw Exception();
    }
  }

  void checklocationempty() {
    if (chosenLocation.address == "" &&
        chosenLocation.city == "" &&
        chosenLocation.country == "" &&
        listEquals(chosenLocation.center, [0.0, 0.0])) {
      setState(() {
        emptylocation = true;
      });
    } else {
      setState(() {
        emptylocation = false;
      });
    }
  }

  void showauthdialog(screenheight, screenwidth) {
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return StatefulBuilder(
            builder: (BuildContext context, setState) {
              return Dialog(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                backgroundColor: Colors.white,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(10, 20, 10, 10),
                  height: screenheight * 0.2,
                  decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.all(Radius.circular(10))),
                  child: Column(children: [
                    const Text(
                      "Login or Signup\nto create an event",
                      style: TextStyle(color: Colors.black, fontSize: 25),
                      textAlign: TextAlign.center,
                      textScaler: TextScaler.linear(1.0),
                    ),
                    SizedBox(
                      height: screenheight * 0.02,
                    ),
                    GestureDetector(
                        onTap: authbuttonpressed
                            ? null
                            : () async {
                                setState(() {
                                  authbuttonpressed = true;
                                });
                                goauthscreen();
                                setState(() {
                                  authbuttonpressed = false;
                                });
                              },
                        child: PrimaryButton(
                            screenwidth: screenwidth,
                            buttonpressed: authbuttonpressed,
                            text: "Continue",
                            buttonwidth: screenwidth * 0.6,
                            bold: false)),
                  ]),
                ),
              );
            },
          );
        });
  }

  void goauthscreen() async {
    await widget.analytics
        .logEvent(name: "auth_from_guest_screen", parameters: {});
    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) => AuthScreen(
                analytics: widget.analytics,
              ),
          fullscreenDialog: true),
    );
  }

  @override
  void initState() {
    selectedinterest = widget.startinterest;
    super.initState();
  }

  @override
  void dispose() {
    titlecontroller.dispose();
    desccontroller.dispose();
    maxpartcontroller.dispose();
    eventdate = DateTime(0, 0, 0);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenwidth = MediaQuery.of(context).size.width;
    final screenheight = MediaQuery.of(context).size.height;
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: widget.allowbackarrow
            ? GestureDetector(
                onTap: () {
                  Navigator.pop(context);
                },
                child: Icon(
                  Icons.arrow_back_ios,
                  color: Theme.of(context).primaryColor,
                ),
              )
            : Container(),
        title: Text(
          "Create Event",
          style: TextStyle(
              color: Theme.of(context).primaryColor,
              fontWeight: FontWeight.bold,
              fontSize: 30),
        ),
        backgroundColor: Colors.white,
        shadowColor: Colors.white,
        elevation: 0.0,
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        child: Column(children: [
          SizedBox(
            height: screenheight * 0.02,
          ),
          InkWell(
            onTap: () async {
              try {
                XFile? image =
                    await picker.pickImage(source: ImageSource.gallery);
                if (image != null) {
                  setState(() {
                    imagepath = File(image.path);
                  });
                  //print(imagepath);
                }
              } catch (e) {
                logic.displayErrorSnackBar(
                    "Could not load. Make sure photo permissions are granted.",
                    context);
              }
            },
            child: ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child: imagepath == null
                  ? Container(
                      color: Theme.of(context).primaryColor,
                      height: 200,
                      width: screenwidth * 0.9,
                      child: Icon(
                        Icons.upload_rounded,
                        color: Colors.white,
                        size: screenheight * 0.18,
                      ),
                    )
                  : Image.file(
                      imagepath,
                      height: 200,
                      width: screenwidth * 0.9,
                      fit: BoxFit.cover,
                    ),
            ),
          ),
          SizedBox(
            height: screenheight * 0.01,
          ),
          const Text(
            "Event Cover is Optional",
            style: TextStyle(color: Color.fromARGB(53, 0, 0, 0)),
            textScaler: TextScaler.linear(1.0),
          ),
          SizedBox(
            height: screenheight * 0.01,
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: screenwidth * 0.2),
            child: TextField(
              style: TextStyle(
                color: Theme.of(context).primaryColor,
                fontWeight: FontWeight.bold,
                fontSize: 30,
              ),
              decoration: InputDecoration(
                focusedBorder: UnderlineInputBorder(
                    borderSide:
                        BorderSide(color: Theme.of(context).primaryColor)),
                hintText: "Event Name",
                hintStyle: const TextStyle(
                  color: Color.fromARGB(39, 0, 0, 0),
                  fontSize: 30,
                ),
              ),
              textAlign: TextAlign.center,
              enableSuggestions: false,
              autocorrect: false,
              controller: titlecontroller,
            ),
          ),
          SizedBox(height: screenheight * 0.02),
          SizedBox(
            width: screenwidth * 0.6,
            child: DropdownButtonFormField(
              borderRadius: BorderRadius.circular(20),
              decoration: InputDecoration(
                  focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Theme.of(context).primaryColor),
              )),
              value: selectedinterest,
              onChanged: (String? newValue) {
                setState(() {
                  selectedinterest = newValue!;
                });
              },
              onSaved: (String? newValue) {
                setState(() {
                  selectedinterest = newValue!;
                });
              },
              items: allinterests.map((String items) {
                return DropdownMenuItem(
                  value: items,
                  child: Text(
                    items,
                    style: const TextStyle(
                        color: Colors.black, fontWeight: FontWeight.w300),
                  ),
                );
              }).toList(),
            ),
          ),
          SizedBox(height: screenheight * 0.02),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: screenwidth * 0.2),
            child: TextField(
              style: const TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.w300,
                fontSize: 15,
              ),
              decoration: InputDecoration(
                focusedBorder: UnderlineInputBorder(
                    borderSide:
                        BorderSide(color: Theme.of(context).primaryColor)),
                hintText: "Description",
                hintStyle: const TextStyle(
                  color: Color.fromARGB(39, 0, 0, 0),
                  fontSize: 15,
                ),
              ),
              textAlign: TextAlign.start,
              enableSuggestions: true,
              autocorrect: true,
              controller: desccontroller,
              keyboardType: TextInputType.text,
              minLines: 1,
              maxLines: 5,
            ),
          ),
          SizedBox(height: screenheight * 0.02),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: screenwidth * 0.2),
            child: TextFormField(
              style: const TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.w300,
                fontSize: 15,
              ),
              decoration: InputDecoration(
                focusedBorder: UnderlineInputBorder(
                    borderSide:
                        BorderSide(color: Theme.of(context).primaryColor)),
                hintText: "Max. Number of Participants",
                hintStyle: const TextStyle(
                  color: Color.fromARGB(39, 0, 0, 0),
                  fontSize: 15,
                ),
              ),
              textAlign: TextAlign.start,
              enableSuggestions: true,
              autocorrect: true,
              controller: maxpartcontroller,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            ),
          ),
          SizedBox(height: screenheight * 0.02),
          GestureDetector(
            onTap: () {
              dp.DatePicker.showDateTimePicker(
                context,
                showTitleActions: true,
                minTime: DateTime.now(),
                onChanged: (date) {
                  setState(() {
                    eventdate = date;
                  });
                },
                onConfirm: (date) {
                  setState(() {
                    eventdate = date;
                  });
                },
                currentTime: DateTime.now(),
              );
            },
            child: Container(
              height: screenwidth * 0.13,
              width: screenwidth * 0.6,
              decoration: BoxDecoration(
                  border: Border.all(width: 1, color: Colors.black),
                  borderRadius: BorderRadius.circular(20)),
              child:
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Text(
                  eventdate == DateTime(0, 0, 0)
                      ? "Date and Time"
                      : "${DateFormat.MMMd().format(eventdate)} @ ${DateFormat('hh:mm a').format(eventdate)}",
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.bold),
                  textScaler: TextScaler.linear(1.0),
                ),
                const SizedBox(
                  width: 5,
                ),
                const Icon(
                  Icons.date_range,
                  size: 15,
                )
              ]),
            ),
          ),
          SizedBox(height: screenheight * 0.02),
          GestureDetector(
            onTap: () async {
              Position _locationData = await Geolocator.getCurrentPosition();
              setState(() {
                LatLngs = [_locationData.latitude, _locationData.longitude];
              });
              AppLocation chosen = emptylocation
                  ? await Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => SearchLocation(
                                locationchosen: false,
                                startlocation: AppLocation(
                                    address: "",
                                    center: [0.0, 0.0],
                                    city: "",
                                    country: ""),
                                curruserLatLng: LatLngs,
                                isbusiness: false,
                              ),
                          settings: RouteSettings(name: "SearchLocation")))
                  : await Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => SearchLocation(
                              locationchosen: true,
                              startlocation: AppLocation(
                                address: chosenLocation.address,
                                center: chosenLocation.center,
                                city: chosenLocation.city,
                                country: chosenLocation.country,
                              ),
                              curruserLatLng: LatLngs,
                              isbusiness: false),
                          settings: RouteSettings(name: "SearchLocation")));
              setState(() {
                chosenLocation = chosen;
              });
              _addMarker(
                  LatLng(chosenLocation.center[0], chosenLocation.center[1]));
              mapController?.moveCamera(CameraUpdate.newLatLngZoom(
                  LatLng(chosenLocation.center[0], chosenLocation.center[1]),
                  17.0));
              checklocationempty();
            },
            child: Container(
              height: screenwidth * 0.13,
              width: screenwidth * 0.6,
              decoration: BoxDecoration(
                  border: Border.all(width: 1, color: Colors.black),
                  borderRadius: BorderRadius.circular(20)),
              child:
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Text(
                  emptylocation ? "Location" : "Change Location",
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.bold),
                  textScaler: TextScaler.linear(1.0),
                ),
                const SizedBox(
                  width: 5,
                ),
                const Icon(
                  Icons.map_rounded,
                  size: 15,
                )
              ]),
            ),
          ),
          SizedBox(
            height: screenheight * 0.02,
          ),
          emptylocation
              ? const SizedBox()
              : SizedBox(
                  height: screenheight * 0.2,
                  width: screenwidth * 0.6,
                  child: GoogleMap(
                    //Map widget from google_maps_flutter package
                    myLocationButtonEnabled: false,
                    zoomGesturesEnabled: true, //enable Zoom in, out on map
                    initialCameraPosition: CameraPosition(
                      //innital position in map
                      target: LatLng(chosenLocation.center[0],
                          chosenLocation.center[1]), //initial position
                      zoom: 14.0, //initial zoom level
                    ),
                    mapType: MapType.normal, //map type
                    markers: Set<Marker>.of(markers.values),
                    onMapCreated: (controller) {
                      //method called when map is created
                      setState(() {
                        mapController = controller;
                      });
                    },
                  ),
                ),
          SizedBox(
            height: emptylocation ? 0 : screenheight * 0.03,
          ),
          Container(
            height: screenwidth * 0.13,
            width: screenwidth * 0.6,
            decoration: BoxDecoration(
                border: Border.all(width: 1, color: Colors.black),
                borderRadius: BorderRadius.circular(21)),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              GestureDetector(
                onTap: () {
                  setState(() {
                    isinviteonly = false;
                  });
                },
                child: Container(
                  width:
                      isinviteonly ? screenwidth * 0.24 : screenwidth * 0.354,
                  decoration: BoxDecoration(
                      color: isinviteonly
                          ? Colors.white
                          : Theme.of(context).primaryColor,
                      border: Border.all(color: Colors.transparent),
                      borderRadius: BorderRadius.circular(20)),
                  child: Center(
                    child: Text(
                      "Public",
                      style: TextStyle(
                          fontSize: isinviteonly ? 16 : 20,
                          color: isinviteonly ? Colors.black : Colors.white),
                      textScaler: TextScaler.linear(1.0),
                    ),
                  ),
                ),
              ),
              GestureDetector(
                onTap: () {
                  setState(() {
                    isinviteonly = true;
                  });
                },
                child: Container(
                  width:
                      isinviteonly ? screenwidth * 0.354 : screenwidth * 0.24,
                  decoration: BoxDecoration(
                      color: isinviteonly
                          ? Theme.of(context).primaryColor
                          : Colors.white,
                      border: Border.all(color: Colors.transparent),
                      borderRadius: BorderRadius.circular(20)),
                  child: Center(
                    child: Text(
                      "Invite-Only",
                      style: TextStyle(
                          fontSize: isinviteonly ? 18 : 14,
                          color: isinviteonly ? Colors.white : Colors.black),
                      textScaler: TextScaler.linear(1.0),
                    ),
                  ),
                ),
              )
            ]),
          ),
          SizedBox(
            height: screenheight * 0.01,
          ),
          Text(
            isinviteonly
                ? "Can only join through shared link"
                : "Anyone can join the event",
            style: const TextStyle(color: Color.fromARGB(53, 0, 0, 0)),
            textScaler: TextScaler.linear(1.0),
          ),
          SizedBox(
            height: screenheight * 0.01,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Checkbox(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(5)),
                  activeColor: Theme.of(context).primaryColor,
                  value: hideparticipants,
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        hideparticipants = value;
                      });
                    }
                  }),
              Text(
                "Hide participant information.",
                style: TextStyle(
                    color: !hideparticipants
                        ? Colors.grey
                        : Theme.of(context).primaryColor),
                textScaler: TextScaler.linear(1.0),
              ),
            ],
          ),
          SizedBox(
            height: screenheight * 0.03,
          ),
          GestureDetector(
              onTap: () {
                showauthdialog(screenheight, screenwidth);
              },
              child: PrimaryButton(
                screenwidth: screenwidth,
                buttonpressed: buttonpressed,
                text: "Create Event",
                buttonwidth: screenwidth * 0.6,
                bold: false,
              )),
          SizedBox(
            height: screenheight * 0.04,
          ),
        ]),
      ),
    );
  }
}
