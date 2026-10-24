import 'dart:convert';
import 'dart:io';

import 'package:fcbaz/features/evolutions/domain/evolution.dart';
import 'package:fcbaz/features/home/home_repository.dart';
import 'package:fcbaz/features/news/domain/news_article.dart';
import 'package:fcbaz/features/sbc/domain/sbc.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> _asset(String name) =>
    jsonDecode(File('assets/data/$name').readAsStringSync())
        as Map<String, dynamic>;

List<Map<String, dynamic>> _items(String name, String key) {
  final data = _asset(name);
  final raw = key.isEmpty ? data : data[key];
  return (raw as List)
      .whereType<Map>()
      .map((e) => Map<String, dynamic>.from(e))
      .toList();
}

void main() {
  test('every SBC challenge resolves a unique id and sourced details', () {
    final sections = _asset('fc27-challenges.json')['sections'] as Map;
    final raw = (sections['sbc'] as List).whereType<Map>();
    final challenges = raw
        .map((e) => SbcChallenge.fromJson(Map<String, dynamic>.from(e)))
        .toList();

    expect(challenges, hasLength(27));
    expect(challenges.map((c) => c.id).toSet(), hasLength(challenges.length));
    for (final challenge in challenges) {
      expect(challenge.id, isNotEmpty);
      expect(challenge.description, isNotEmpty);
      expect(challenge.requirements, isNotEmpty);
    }
  });

  test('every evolution resolves a unique id and structured requirements', () {
    final items = _items('fc27-evolutions.json', 'evolutions');
    final evolutions = items.map(Evolution.fromJson).toList();

    expect(evolutions, hasLength(19));
    expect(evolutions.map((e) => e.id).toSet(), hasLength(evolutions.length));
    for (final evolution in evolutions) {
      expect(evolution.id, isNotEmpty);
      expect(evolution.requirementData, isNotEmpty);
    }

    final goalkeeper = evolutions.firstWhere((e) => e.id == '2603-poor-sophia');
    expect(
      goalkeeper.requirementData,
      contains(containsPair('type', 'position')),
    );
    expect(goalkeeper.requirementData, contains(containsPair('max', 81)));

    final excluded = evolutions.firstWhere(
      (e) => e.id == '2562-middle-management',
    );
    final excludedTypes = excluded.requirementData
        .map((e) => e['type'])
        .toSet();
    expect(excludedTypes, contains('excluded_position'));
    expect(excludedTypes, contains('overall'));

    final rarity = evolutions.firstWhere(
      (e) => e.id == '2561-future-stars-academy-iv',
    );
    expect(rarity.requirementData.map((e) => e['type']), contains('rarity'));
  });

  test('every objective and task resolves a stable id and real target', () {
    final sections = _asset('fc27-challenges.json')['sections'] as Map;
    final raw = (sections['objectives'] as List).whereType<Map>();
    final objectives = raw
        .map((e) => HomeObjective.fromJson(Map<String, dynamic>.from(e)))
        .toList();

    expect(objectives, hasLength(41));
    expect(objectives.map((e) => e.id).toSet(), hasLength(objectives.length));

    var tasks = 0;
    var withTarget = 0;
    for (final objective in objectives) {
      expect(objective.id, isNotEmpty);
      final taskIds = objective.tasks.map((e) => e.id).toList();
      expect(taskIds, everyElement(isNotEmpty));
      expect(taskIds.toSet(), hasLength(taskIds.length));
      tasks += taskIds.length;
      withTarget += objective.tasks.where((e) => e.target > 0).length;
    }
    expect(tasks, 162);
    expect(withTarget, greaterThanOrEqualTo(100));
  });

  test('news articles always expose an intro and usable tags', () {
    final items = _items('fc27-news.json', 'items');
    final articles = items.map(NewsArticle.fromJson).toList();

    expect(articles, hasLength(13));
    expect(articles.map((e) => e.id).toSet(), hasLength(articles.length));
    for (final article in articles) {
      expect(article.displayTitle, isNotEmpty);
      expect(article.intro, isNotEmpty);
      expect(article.tagFa.trim(), isNotEmpty);
    }

    final tags = articles.map((e) => e.tagFa.trim()).toSet();
    expect(tags.length, greaterThanOrEqualTo(2));

    final grounds = articles.firstWhere(
      (e) => e.title.contains('The Grounds Developer Archetypes'),
    );
    expect(grounds.intro, grounds.displaySummary);
  });
}
