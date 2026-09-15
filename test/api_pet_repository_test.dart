import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:pr_2/api/app_exceptions.dart';
import 'package:pr_2/api/directory_cache.dart';
import 'package:pr_2/models/pet.dart';
import 'package:pr_2/models/pet_query.dart';
import 'package:pr_2/repositories/api_pet_repository.dart';

class _ScriptedAdapter implements HttpClientAdapter {
  _ScriptedAdapter(this._handler);

  final Future<ResponseBody> Function(RequestOptions options) _handler;

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) {
    return _handler(options);
  }
}

ResponseBody _json(int status, Object data) {
  return ResponseBody.fromString(
    jsonEncode(data),
    status,
    headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    },
  );
}

Dio _dioWith(_ScriptedAdapter adapter) {
  final dio = Dio(BaseOptions(baseUrl: 'http://test/api'));
  dio.httpClientAdapter = adapter;
  return dio;
}

const _samplePet = Pet(
  id: 0,
  name: 'Дубль',
  species: 'cat',
  breed: 'Дворняга',
  chipNumber: 'CHIP-0001',
  ageMonths: 12,
  weightKg: 3,
  clinicId: 1,
  ownerIds: [1],
  serviceIds: [1],
);

void main() {
  test('find parses page of pets', () async {
    final dio = _dioWith(
      _ScriptedAdapter((options) async {
        expect(options.path, '/pets');
        expect(options.queryParameters['page'], 1);
        return _json(200, {
          'items': [
            {
              'id': 1,
              'name': 'Барсик',
              'species': 'cat',
              'breed': 'Британский',
              'chipNumber': 'CHIP-0001',
              'ageMonths': 24,
              'weightKg': 4.5,
              'clinicId': 1,
              'ownerIds': [1],
              'serviceIds': [1],
              'notes': '',
            },
          ],
          'page': 1,
          'size': 10,
          'total': 1,
        });
      }),
    );

    final repo = ApiPetRepository(dio, searchCancel: SearchCancel());
    final page = await repo.find(const PetQuery(page: 1, size: 10));
    expect(page.total, 1);
    expect(page.items.single.name, 'Барсик');
    expect(page.items.single.chipNumber, 'CHIP-0001');
  });

  test('create returns created pet', () async {
    final dio = _dioWith(
      _ScriptedAdapter((options) async {
        expect(options.method, 'POST');
        expect(options.path, '/pets');
        return _json(201, {
          'id': 99,
          'name': 'Новый',
          'species': 'dog',
          'breed': 'Корги',
          'chipNumber': 'CHIP-9999',
          'ageMonths': 10,
          'weightKg': 8,
          'clinicId': 1,
          'ownerIds': [1],
          'serviceIds': [1],
          'notes': '',
        });
      }),
    );

    final repo = ApiPetRepository(dio);
    final pet = await repo.create(
      const Pet(
        id: 0,
        name: 'Новый',
        species: 'dog',
        breed: 'Корги',
        chipNumber: 'CHIP-9999',
        ageMonths: 10,
        weightKg: 8,
        clinicId: 1,
        ownerIds: [1],
        serviceIds: [1],
      ),
    );
    expect(pet.id, 99);
    expect(pet.name, 'Новый');
  });

  test('422 validation maps field errors for chipNumber', () async {
    final dio = _dioWith(
      _ScriptedAdapter((options) async {
        return _json(422, {
          'message': 'Ошибка валидации',
          'errors': {
            'chipNumber': 'Питомец с таким номером чипа уже существует',
          },
        });
      }),
    );

    final repo = ApiPetRepository(dio);
    expect(
      () => repo.create(_samplePet),
      throwsA(
        isA<ValidationException>().having(
          (e) => e.fieldErrors['chipNumber'],
          'chipNumber',
          contains('чипа'),
        ),
      ),
    );
  });

  test('server unavailable becomes NetworkException', () async {
    final dio = _dioWith(
      _ScriptedAdapter((options) async {
        throw DioException(
          requestOptions: options,
          type: DioExceptionType.connectionError,
          error: 'Connection refused',
        );
      }),
    );

    final repo = ApiPetRepository(dio);
    expect(() => repo.create(_samplePet), throwsA(isA<NetworkException>()));
  });

  test('404 findById returns null', () async {
    final dio = _dioWith(
      _ScriptedAdapter((options) async {
        return _json(404, {'message': 'Объект не найден'});
      }),
    );

    final repo = ApiPetRepository(dio);
    final pet = await repo.findById(404);
    expect(pet, isNull);
  });

  test('softDelete sends DELETE without hard flag', () async {
    var called = false;
    final dio = _dioWith(
      _ScriptedAdapter((options) async {
        called = true;
        expect(options.method, 'DELETE');
        expect(options.path, '/pets/5');
        expect(options.queryParameters['hard'], isNull);
        return ResponseBody.fromString('', 204);
      }),
    );

    final repo = ApiPetRepository(dio);
    await repo.softDelete(5);
    expect(called, isTrue);
  });
}
