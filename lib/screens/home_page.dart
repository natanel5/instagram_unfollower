import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String? followingFilePath;
  String? followersFilePath;
  String? followingFileName;
  String? followersFileName;

  List<Map<String, String>> unfollowers = [];
  bool isLoading = false;

  Future<void> _pickFile(bool isFollowingFile) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result != null && result.files.single.path != null) {
        setState(() {
          if (isFollowingFile) {
            followingFilePath = result.files.single.path;
            followingFileName = result.files.single.name;
          } else {
            followersFilePath = result.files.single.path;
            followersFileName = result.files.single.name;
          }
          unfollowers = [];
        });
      } else {
        print("User canceled file picking.");
      }
    } catch (e) {
      print("Error picking file: $e");
    }
  }

  Future<void> _findUnfollowers() async {
    if (followingFilePath == null || followersFilePath == null) {
      print("Please select both files first.");
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      final followingFile = File(followingFilePath!);
      final followersFile = File(followersFilePath!);

      final followingString = await followingFile.readAsString();
      final followersString = await followersFile.readAsString();

      // Decode 'following' as a Map (Object)
      final Map<String, dynamic> followingData = json.decode(followingString);
      // Decode 'followers' as a List
      final List<dynamic> followersData = json.decode(followersString);

      // Extract the *actual* list from the 'following' Map
      final List<dynamic> followingList =
          followingData['relationships_following'] ?? [];

      // The 'followers' data is already the correct list
      final List<dynamic> followersList = followersData;

      // Now we pass the correct lists to the parser function
      final Map<String, String> followingMap = _parseData(followingList);
      final Set<String> followersSet = _parseData(followersList).keys.toSet();

      final Set<String> unfollowerUsernames =
          followingMap.keys.toSet().difference(followersSet);

      final List<Map<String, String>> results = [];
      for (var username in unfollowerUsernames) {
        if (followingMap.containsKey(username)) {
          results.add(
              {'username': username, 'href': followingMap[username]!});
        }
      }

      results.sort((a, b) => a['username']!.compareTo(b['username']!));

      setState(() {
        unfollowers = results;
        isLoading = false;
      });
    } catch (e) {
      print("Error processing files: $e");
      setState(() {
        isLoading = false;
      });
    }
  }

  // --- PARSER WITH DEBUG PRINTS ---
  Map<String, String> _parseData(List<dynamic> jsonList) {
    Map<String, String> dataMap = {};
    // DEBUG: Print the total length of the list being parsed
    print("--- STARTING PARSE (List length: ${jsonList.length}) ---");

    for (var item in jsonList) {
      // Check 1: Make sure 'string_list_data' exists and is a List
      if (item['string_list_data'] == null ||
          !(item['string_list_data'] is List) ||
          item['string_list_data'].isEmpty) {
        // DEBUG: Print if we skip an item
        print("PARSING: Skipped item, missing 'string_list_data'");
        continue; // Skip this whole item
      }

      var data = item['string_list_data'][0];
      if (data == null) {
        // DEBUG: Print if the data block is null
        print("PARSING: Skipped item, 'string_list_data'[0] is null");
        continue; // Skip if the data block is null
      }

      String? username;
      String? href;

      // 1. Get the Href
      if (data['href'] != null && data['href'] is String) {
        href = data['href'];
      }

      // 2. Get the Username
      // Try 'title' first
      if (item['title'] != null && item['title'] is String && item['title'].isNotEmpty) {
        username = item['title'];
        // DEBUG: Print if we found a username in 'title'
        print("PARSING: Found username in 'title': $username");
      }
      // If 'title' was empty, try 'value'
      else if (data['value'] != null && data['value'] is String) {
        username = data['value'];
        // DEBUG: Print if we found a username in 'value'
        print("PARSING: Found username in 'value': $username");
      } else {
        // DEBUG: Print if we failed to find a username
        print("PARSING: FAILED to find username in 'title' or 'value'. Item data: $item");
      }

      // 3. Only add if we found both
      if (username != null && username.isNotEmpty && href != null) {
        dataMap[username] = href;
      }
    }
    // DEBUG: Print how many users we successfully parsed
    print("--- PARSING COMPLETE (Found ${dataMap.length} users) ---");
    return dataMap;
  }
  // --- END OF DEBUG PARSER ---

  Future<void> _launchUrl(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      print("Could not launch $urlString");
    }
  }

  @override
  Widget build(BuildContext context) {
    // ... (The build method is unchanged) ...
    return Scaffold(
      appBar: AppBar(
        title: const Text('Instagram Unfollowers'),
        backgroundColor: Colors.pink[800],
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton.icon(
              icon: const Icon(Icons.person_add),
              label: const Text('1. Select following.json'),
              onPressed: () => _pickFile(true),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
            if (followingFileName != null)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  "Selected: $followingFileName",
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      color: Colors.green, fontWeight: FontWeight.bold),
                ),
              ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              icon: const Icon(Icons.people),
              label: const Text('2. Select followers_1.json'),
              onPressed: () => _pickFile(false),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
            if (followersFileName != null)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  "Selected: $followersFileName",
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      color: Colors.green, fontWeight: FontWeight.bold),
                ),
              ),
            const SizedBox(height: 20),
            FilledButton.icon(
              icon: const Icon(Icons.compare_arrows),
              label: const Text('Find Unfollowers'),
              onPressed: _findUnfollowers,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
            const Divider(height: 40),
            Text(
              'Results: (${unfollowers.length} found)',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: isLoading
                  ? const Center(
                      child: CircularProgressIndicator(),
                    )
                  : unfollowers.isEmpty
                      ? const Center(
                          child: Text('Results will appear here...'),
                        )
                      : ListView.builder(
                          itemCount: unfollowers.length,
                          itemBuilder: (context, index) {
                            final user = unfollowers[index];
                            final username = user['username']!;
                            final href = user['href']!;

                            return Card(
                              child: ListTile(
                                title: Text(username),
                                trailing: const Icon(Icons.open_in_new,
                                    color: Colors.blue),
                                onTap: () {
                                  _launchUrl(href);
                                },
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}