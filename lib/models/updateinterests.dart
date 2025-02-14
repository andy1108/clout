import 'package:clout/defs/user.dart';
import 'package:flutter/material.dart';

class UpdateInterests extends StatefulWidget {
  UpdateInterests({
    Key? key,
    required this.curruser,
  }) : super(key: key);
  AppUser curruser;
  @override
  State<UpdateInterests> createState() => _UpdateInterestsState();
}

class _UpdateInterestsState extends State<UpdateInterests> {
  List allinterests = [
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
  Widget _listviewitem(String interest) {
    Widget thiswidget = Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15.0),
        border: Border.all(
            width: widget.curruser.interests.contains(interest) ? 2 : 0,
            color: widget.curruser.interests.contains(interest)
                ? Theme.of(context).primaryColor
                : Colors.black),
        image: DecorationImage(
            opacity: widget.curruser.interests.contains(interest) ? 0.8 : 1,
            image: AssetImage(
              "assets/images/interestbanners/${interest.toLowerCase()}.jpeg",
            ),
            fit: BoxFit.cover),
      ),
      child: Center(
          child: Text(
        interest,
        style: TextStyle(
            fontSize: 33,
            fontWeight: FontWeight.bold,
            color: widget.curruser.interests.contains(interest)
                ? Theme.of(context).primaryColor
                : Colors.white),
        textScaler: TextScaler.linear(1.0),
      )),
    );

    return GestureDetector(
      onTap: () {
        if (widget.curruser.interests.contains(interest)) {
          setState(() {
            widget.curruser.interests
                .removeWhere((element) => element == interest);
          });
        } else {
          setState(() {
            widget.curruser.interests.add(interest);
          });
        }
      },
      child: thiswidget,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Interests",
          style: TextStyle(
              color: Colors.black, fontWeight: FontWeight.bold, fontSize: 30),
          textScaler: TextScaler.linear(1.0),
        ),
        backgroundColor: Colors.white,
        elevation: 0.0,
        centerTitle: true,
        leading: GestureDetector(
          onTap: () {
            if (widget.curruser.interests.length >= 3) {
              Navigator.pop(context, widget.curruser.interests);
            }
          },
          child: const Icon(
            Icons.arrow_back_ios,
            color: Colors.black,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(8.0, 0, 8.0, 8.0),
        child: Column(
          children: [
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.fromLTRB(0, 16, 0, 0),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2),
                shrinkWrap: true,
                itemCount: allinterests.length,
                itemBuilder: ((context, index) {
                  return Padding(
                    padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
                    child: _listviewitem(allinterests[index]),
                  );
                }),
              ),
            )
          ],
        ),
      ),
    );
  }
}
