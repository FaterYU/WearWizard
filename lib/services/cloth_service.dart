import 'dart:async';
import 'dart:convert';

import 'package:wearwizard/services/api_http.dart';
import 'package:wearwizard/services/file_service.dart';

enum Season { spring, summer, autumn, winter }

enum Style { casual, formal, sporty, elegant }

enum CategoryType { base, bottom, outerwear, accessories }

Map<CategoryType, String> categoryMap = {
  CategoryType.base: 'base',
  CategoryType.bottom: 'bottom',
  CategoryType.outerwear: 'outerwear',
  CategoryType.accessories: 'accessories',
};

class Cloth {
  String picture;
  Cloth({
    id,
    this.picture = '',
    note,
    category,
    season,
    colorType,
    style,
  });

  factory Cloth.add(Map<String, dynamic> json) {
    if (json['code'] == 20000 &&
        json['msg'] is String &&
        json['desc'] is String) {
      return Cloth();
    } else if (json['msg'] is String && json['desc'] is String) {
      throw Exception(json['msg'] + ' Description: ' + json['desc']);
    } else {
      throw Exception('Failed to add cloth for API structure error');
    }
  }

  Future<Cloth> add(String picture, String note, String category, Season season,
      String colorType, Style style) async {
    final response = await ApiService.post('clothes/add', body: {
      'pic': picture,
      'note': note,
      'category': category,
      'season': season.index,
      'colorType': colorType,
      'style': style.index,
    });

    if (response.statusCode == 200) {
      return Cloth.add(jsonDecode(response.body));
    } else {
      throw Exception('Failed to add cloth for API error');
    }
  }

  Future<Map<String, dynamic>> spilt(String picture) async {
    final response = await ApiService.postFile('clothes/splitClothes',
        body: {}, file: {'file': picture});

    if (response.statusCode == 200) {
      // Fix the API error response
      var fixBody = response.body;
      var reg = RegExp(r'(?<=\\"label\\":)[\w\s]+');
      var match = reg.allMatches(fixBody);
      for (var item in match) {
        String val = item.group(0)!;
        fixBody = fixBody.replaceAll(val, '\\"' + val + '\\"');
      }
      var json = jsonDecode(fixBody);
      if (json['code'] == 20000 && json['msg'] == 'ok') {
        var result = jsonDecode(json['data'][0]);
        for (var obj = 0; obj < result['count']; obj++) {
          result['objects'][obj]['image'] =
              previewHostname + json['data'][obj + 1];
        }
        return result;
      } else {
        throw Exception(json['msg'] + ' Description: ' + json['desc']);
      }
    } else {
      throw Exception('Failed to add cloth for API error');
    }
  }

  Future<List<Cloth>> getClothesByCategory(
      CategoryType category, int page, int pageSize) async {
    final response = await ApiService.get(
        'clothes/getByCategory?category=${categoryMap[category]}&page=$page&pageSize=$pageSize');

    if (response.statusCode == 200) {
      var json = jsonDecode(response.body);
      try {
        List<Cloth> clothes = [];
        for (var item in json['data']) {
          clothes.add(Cloth(
            id: item['clothesId'],
            picture: item['pic'],
          ));
        }
        return clothes;
      } catch (e) {
        throw Exception('Failed to get clothes for API structure error');
      }
    } else {
      throw Exception('Failed to get clothes for API error');
    }
  }
}
