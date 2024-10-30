import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

// ignore: must_be_immutable
class OpportunityListWidget extends StatefulWidget {
  final List<dynamic> opportunities;
  final List<dynamic>? pipeline;
  ScrollController? scroll;
  bool? scrolling;
  String searchQuery;
  Function() onLoadMore;
  OpportunityListWidget(
      {required this.opportunities,
      this.pipeline,
      this.scroll,
      this.scrolling,
      required this.searchQuery,
      required this.onLoadMore});

  @override
  _OpportunityListWidgetState createState() => _OpportunityListWidgetState();
}

class _OpportunityListWidgetState extends State<OpportunityListWidget> {
  int selected = 0;
  double monetary = 0;
  String formattedMonetary = "0.00";

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height:MediaQuery.of(context).size.height *8/100,
      child: RefreshIndicator(
        onRefresh: _refreshData,
        child: ListView.builder(
          padding: EdgeInsets.zero,
          itemCount: widget.opportunities.length,
          itemBuilder: (context, index) {
            var currentOpportunity = widget.opportunities[index];
            var opportunityName = currentOpportunity['name'] ?? '';
            var opportunityPhone = currentOpportunity['contact']['phone'] ?? '';
            if (widget.searchQuery.isNotEmpty &&
      !opportunityName.toLowerCase().contains(widget.searchQuery.toLowerCase()) &&
      !opportunityPhone.toLowerCase().contains(widget.searchQuery.toLowerCase())) {
    return SizedBox.shrink(); // Return an empty widget if not a match
  }
            return Padding(
              padding: const EdgeInsets.only(right: 15.0),
              child: Card(
                color: Color(0xFF1C1C1E),
                child: Container(
                  height: 125,
                  width: double.infinity,
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              child: Row(
                                children: [
                                  Icon(
                                    CupertinoIcons.person_alt_circle,
                                  ),
                                  SizedBox(
                                    width: 5,
                                  ),
                                  Container(
                                    width: 150,
                                    child: Text(
                                      opportunityName,
                                      textAlign: TextAlign.start,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                          fontSize: 15,
                                           fontFamily: 'SF',
                                          color: Colors.white,
                                          fontWeight: FontWeight.w500),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Spacer(),
                          ],
                        ),
                        SizedBox(
                          height: 5,
                        ),
                        Text(
                          opportunityPhone ?? "",
                          textAlign: TextAlign.start,
                          style: TextStyle(
                              fontSize: 12,
                                           fontFamily: 'SF',
                              color: Colors.white,
                              fontWeight: FontWeight.w400),
                        ),
                        SizedBox(
                          height: 10,
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            GestureDetector(
                              onTap: () {
                                _launchURL("sms:$opportunityPhone");
                              },
                              child: Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Padding(
                                    padding: EdgeInsets.symmetric(
                                        horizontal: 18, vertical: 2),
                                    child: Icon(Icons.chat_bubble,
                                        size: 25, color: Colors.white),
                                  )),
                            ),
                            SizedBox(
                              width: 5,
                            ),
                            GestureDetector(
                              onTap: () {
                                _launchURL("tel:$opportunityPhone");
                              },
                              child: Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Padding(
                                    padding: EdgeInsets.symmetric(
                                        horizontal: 18, vertical: 2),
                                    child: Icon(Icons.call,
                                        size: 25, color: Colors.white),
                                  )),
                            ),
                            SizedBox(
                              width: 5,
                            ),
                            GestureDetector(
                              onTap: () {
                                _launchWhatsapp(opportunityPhone);
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Padding(
                                    padding: EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 2),
                                    child: Image.asset(
                                      'assets/images/whatsapp.png',
                                      fit: BoxFit.contain,
                                      scale: 12,
                                    )),
                              ),
                            ),
                          ],
                        )
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> _refreshData() async {
    // Add your refresh logic here
    await Future.delayed(
        Duration(seconds: 1)); // Simulating some async operation
    widget.onLoadMore();
    setState(() {
      // Update your data here
    });
  }

  _launchURL(String url) async {
    await launch(Uri.parse(url).toString());
  }

  void _launchWhatsapp(String number) async {
    String url = 'https://wa.me/$number';
    try {
      await launch(url);
    } catch (e) {
      throw 'Could not launch $url';
    }
  }
}
