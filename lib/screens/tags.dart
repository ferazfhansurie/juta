import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:juta_app/utils/toast.dart';

class TagScreen extends StatefulWidget {
  List<String> contactId;
  String accessToken;
  List<dynamic> label;
  TagScreen({super.key,required this.contactId,required this.accessToken,required this.label});

  @override
  State<TagScreen> createState() => _TagScreenState();
}

class _TagScreenState extends State<TagScreen> {
            TextEditingController tagController = TextEditingController();
              List<dynamic> tags = [];
                List<dynamic> selected = [];
     @override
     void initState() {
   init() ;
   selected.addAll(widget.label);
       super.initState();
       
     }
Future<void> init() async {
 tags = await getTags();
}
          Future<List<dynamic>> getTags() async {
  String baseUrl = 'https://rest.gohighlevel.com';
  String tagsEndpoint = '/v1/tags';
  List<dynamic> tagsList = [];

  try {
    Uri uri = Uri.parse('$baseUrl$tagsEndpoint');
    Map<String, String> headers = {
      'Authorization': 'Bearer ${widget.accessToken}',
    };

    http.Response response = await http.get(uri, headers: headers);
  
    if (response.statusCode == 200) {
      // Parse the response body and extract tags
      Map<String, dynamic> responseData = json.decode(response.body);

      if (responseData.containsKey('tags')) {
        List<dynamic> tags = responseData['tags'];
        tagsList = tags.map((tag) => tag['name'].toString()).toList();
        setState(() {
          
        });
      } else {
        print('No tags found in the response.');
      }
    } else {
      // Handle error response
      print('Error: ${response.statusCode} - ${response.reasonPhrase}');
    }
  } catch (error) {
    // Handle exceptions or errors during the request
    print('Error: $error');
  }

  return tagsList;
}
  @override
  Widget build(BuildContext context) {
    return Scaffold(
          appBar: AppBar(
        backgroundColor:Color.fromARGB(255, 255, 255, 255),
        automaticallyImplyLeading: false,
        title: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              GestureDetector(
                  onTap: () {
                    Navigator.of(context).pop();
                  },
                  child:Text( 'Cancel',style: TextStyle( color: Color(0xFF2D3748),fontSize:16),
                     )),
          
              
            
               GestureDetector(
               
                child: Container(
                
                  child: Text("Tags",style: const TextStyle(color: Color(0xFF2D3748),fontSize: 18),)),
              ),
          
              
            
          
          
              
              GestureDetector(
                  onTap: () async {
                print(widget.label);
                print(selected);
                if(widget.label.isNotEmpty){
                    removeTagsToContact(widget.label);
                }
                if(selected.isNotEmpty) {
                  addTagsToContact( selected);
                }
                    Navigator.pop(context,true);
                  },
                  child:Text( 'Update Tag',style: TextStyle( color: Color.fromARGB(255, 59, 123, 233),fontSize: 16),
                     )),
                 
                         
               
                  
            ],
          ),
        ),

      ),
      body: Container(
            child:Column(
              children: [
               
            
         
                   Expanded(
                  child: ListView.builder(
                      itemCount: tags.length,
                      itemBuilder: ((context, index) {
                        return GestureDetector(
                          onTap: (){
                            setState(() {
                              if(!selected.contains(tags[index])){
 selected.add(tags[index]);
                              }else{
                                 selected.remove(tags[index]);
                              }
                             
                     
                      
                            });
                          },
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Padding(
                                                padding: const EdgeInsets.symmetric(horizontal: 5,vertical: 8),
                                                child: Card(
                                                  color:(selected.contains(tags[index]))?Color(0xFF2D3748):Colors.white,
                                                  child: Container(
                                                     width: 300,
                                                    child: Padding(
                                                      padding: const EdgeInsets.all(10),
                                                      child:    Text(
                                                                                                  tags[index],
                                                                                                  textAlign: TextAlign.center,
                                                          style: TextStyle(
                                                            color:(selected.contains(tags[index]))?Color.fromARGB(255, 255, 255, 255):Color(0xFF2D3748) ,
                                                             fontFamily: 'SF',
                                                             fontWeight: FontWeight.bold,
                                                          fontSize: 16
                                                                                                  
                                                          ),
                                                                                                  ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                           
                            ],
                          ),
                        );
                      })),
                ),
                        Divider(),   
                               Container(
                                                                    width: 300,
                                                                    child: Card(
                                                                                 
                                                                                                        child: TextField(
                                                                                                           
                                                                                                            style:const TextStyle(color: Colors.black,fontFamily: 'SF',),
                                                                                                            controller: tagController,
                                                                                                            decoration: const InputDecoration(
                                                                                                              border: InputBorder.none,
                                                                                                            ),
                                                                                                          ),
                                                                                                      ),
                                                                  ), 
                                                                                                        
               Padding(
                 padding: const EdgeInsets.all(15),
                 child: GestureDetector(
                    onTap: () async {
               addTagsToContact([tagController.text]);
                    },
                     child: Container(
                        width: 200,
                                 margin:
                        const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
                                 padding: const EdgeInsets.all(8.0),
                                 decoration: BoxDecoration(
                      color:const Color(0xFF019F7D),
                      borderRadius: BorderRadius.circular(12),
                                 ),
                                 child: const Center(
                                   child: Text(
                                                     "Create Tag",
                                                     style: TextStyle(fontSize: 18.0, color: Colors.white,
                                                   fontFamily: 'SF',),
                                   ),
                                 ),
                               ),
                   ),
               ),
      SizedBox(height: 15,)
            
              ],
            ),
          ),
    );
  }
       Future<void> removeTagsToContact( List<dynamic> tags) async {
        for(int i = 0 ; i < widget.contactId.length;i++){
 final String baseUrl = 'https://rest.gohighlevel.com/v1/contacts/${widget.contactId[0]}/tags/';
  final String apiKey = widget.accessToken!; // Replace 'YOUR_API_KEY' with your actual API key

  // Create the request body
  Map<String, dynamic> requestBody = {
    "tags": tags,
  };

  // Convert the request body to JSON
  String jsonBody = json.encode(requestBody);

  // Set up the headers
  Map<String, String> headers = {
    'Authorization': 'Bearer $apiKey',
    'Content-Type': 'application/json',
  };

  try {
    // Send POST request to add tags to the contact
    http.Response response = await http.delete(
      Uri.parse(baseUrl),
      headers: headers,
      body: jsonBody,
    );
    if (response.statusCode == 200) {
    //  await _handleRefresh();

      Toast.show(context,'success','Tag Added');
   
      print('Tags added to contact successfully');
    } else {
      // Handle the error
          Toast.show(context,'danger','Failed to add tags');
      print('Failed to add tags. Status code: ${response.statusCode}');
      print('Response body: ${response.body}');
    }
  } catch (error) {
    // Handle any potential exceptions
    print('Error adding tags: $error');
  }

        }
 


}
      Future<void> addTagsToContact( List<dynamic> tags) async {
        for(int i = 0 ;i<  widget.contactId.length;i ++){
 final String baseUrl = 'https://rest.gohighlevel.com/v1/contacts/${widget.contactId[i]}/tags/';
  final String apiKey = widget.accessToken; // Replace 'YOUR_API_KEY' with your actual API key

  // Create the request body
  Map<String, dynamic> requestBody = {
    "tags": tags,
  };

  // Convert the request body to JSON
  String jsonBody = json.encode(requestBody);

  // Set up the headers
  Map<String, String> headers = {
    'Authorization': 'Bearer $apiKey',
    'Content-Type': 'application/json',
  };

  try {
    // Send POST request to add tags to the contact
    http.Response response = await http.post(
      Uri.parse(baseUrl),
      headers: headers,
      body: jsonBody,
    );
    if (response.statusCode == 200) {
    //  await _handleRefresh();
 
      Toast.show(context,'success','Tag Added');
   
      print('Tags added to contact successfully');
    } else {
      // Handle the error
          Toast.show(context,'danger','Failed to add tags');
      print('Failed to add tags. Status code: ${response.statusCode}');
      print('Response body: ${response.body}');
    }
  } catch (error) {
    // Handle any potential exceptions
    print('Error adding tags: $error');
  }
        }
 



}
}