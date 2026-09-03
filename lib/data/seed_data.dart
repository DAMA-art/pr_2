import '../models/owner.dart';
import '../models/pet.dart';

final List<Owner> seedOwners = [
  const Owner(id: 1, lastName: 'Иванов', firstName: 'Алексей', phone: '+7-900-111-22-33', email: 'ivanov@mail.ru', city: 'Москва', country: 'Россия'),
  const Owner(id: 2, lastName: 'Петрова', firstName: 'Мария', phone: '+7-900-222-33-44', email: 'petrova@mail.ru', city: 'Санкт-Петербург', country: 'Россия'),
  const Owner(id: 3, lastName: 'Сидоров', firstName: 'Дмитрий', phone: '+7-900-333-44-55', email: 'sidorov@mail.ru', city: 'Казань', country: 'Россия'),
  const Owner(id: 4, lastName: 'Козлова', firstName: 'Елена', phone: '+7-900-444-55-66', email: 'kozlova@mail.ru', city: 'Новосибирск', country: 'Россия'),
  const Owner(id: 5, lastName: 'Смирнов', firstName: 'Игорь', phone: '+7-900-555-66-77', email: 'smirnov@mail.ru', city: 'Екатеринбург', country: 'Россия'),
  const Owner(id: 6, lastName: 'Васильева', firstName: 'Анна', phone: '+7-900-666-77-88', email: 'vasileva@mail.ru', city: 'Москва', country: 'Россия'),
  const Owner(id: 7, lastName: 'Морозов', firstName: 'Павел', phone: '+7-900-777-88-99', email: 'morozov@mail.ru', city: 'Сочи', country: 'Россия'),
  const Owner(id: 8, lastName: 'Новикова', firstName: 'Ольга', phone: '+7-900-888-99-00', email: 'novikova@mail.ru', city: 'Краснодар', country: 'Россия'),
  const Owner(id: 9, lastName: 'Фёдоров', firstName: 'Сергей', phone: '+7-900-999-00-11', email: 'fedorov@mail.ru', city: 'Москва', country: 'Россия'),
  const Owner(id: 10, lastName: 'Кузнецова', firstName: 'Татьяна', phone: '+7-900-100-11-22', email: 'kuznetsova@mail.ru', city: 'Санкт-Петербург', country: 'Россия'),
];

final List<Pet> seedPets = [
  const Pet(id: 1, name: 'Барсик', species: 'cat', breed: 'Британская короткошёрстная', ageMonths: 36, weightKg: 5.2, ownerId: 1, serviceIds: [1, 2], notes: 'Любит расчёсывание'),
  const Pet(id: 2, name: 'Шарик', species: 'dog', breed: 'Лабрадор', ageMonths: 48, weightKg: 32.0, ownerId: 2, serviceIds: [1, 3], notes: 'Активный'),
  const Pet(id: 3, name: 'Мурка', species: 'cat', breed: 'Сиамская', ageMonths: 24, weightKg: 3.8, ownerId: 3, serviceIds: [2], notes: ''),
  const Pet(id: 4, name: 'Рекс', species: 'dog', breed: 'Немецкая овчарка', ageMonths: 60, weightKg: 38.5, ownerId: 4, serviceIds: [1, 3, 4], notes: 'Служебная собака'),
  const Pet(id: 5, name: 'Пушок', species: 'rabbit', breed: 'Ангорский', ageMonths: 18, weightKg: 2.1, ownerId: 5, serviceIds: [2], notes: 'Длинная шерсть'),
  const Pet(id: 6, name: 'Кеша', species: 'bird', breed: 'Волнистый попугай', ageMonths: 12, weightKg: 0.05, ownerId: 6, serviceIds: [5], notes: ''),
  const Pet(id: 7, name: 'Боня', species: 'dog', breed: 'Йоркширский терьер', ageMonths: 30, weightKg: 3.2, ownerId: 7, serviceIds: [1, 2], notes: 'Маленькая'),
  const Pet(id: 8, name: 'Снежок', species: 'cat', breed: 'Персидская', ageMonths: 42, weightKg: 4.5, ownerId: 8, serviceIds: [2], notes: 'Требует регулярного ухода'),
  const Pet(id: 9, name: 'Тузик', species: 'dog', breed: 'Дворняжка', ageMonths: 72, weightKg: 15.0, ownerId: 9, serviceIds: [1], notes: ''),
  const Pet(id: 10, name: 'Луна', species: 'cat', breed: 'Мейн-кун', ageMonths: 20, weightKg: 6.8, ownerId: 10, serviceIds: [1, 2], notes: 'Крупная'),
  const Pet(id: 11, name: 'Гром', species: 'dog', breed: 'Хаски', ageMonths: 36, weightKg: 25.0, ownerId: 1, serviceIds: [1, 3], notes: 'Энергичный'),
  const Pet(id: 12, name: 'Васька', species: 'cat', breed: 'Дворовая', ageMonths: 48, weightKg: 4.0, ownerId: 2, serviceIds: [2], notes: ''),
  const Pet(id: 13, name: 'Джек', species: 'dog', breed: 'Джек-рассел-терьер', ageMonths: 28, weightKg: 7.5, ownerId: 3, serviceIds: [1], notes: ''),
  const Pet(id: 14, name: 'Мила', species: 'cat', breed: 'Рэгдолл', ageMonths: 15, weightKg: 4.2, ownerId: 4, serviceIds: [2], notes: 'Спокойная'),
  const Pet(id: 15, name: 'Барон', species: 'dog', breed: 'Ротвейлер', ageMonths: 54, weightKg: 42.0, ownerId: 5, serviceIds: [1, 4], notes: ''),
  const Pet(id: 16, name: 'Зоя', species: 'rabbit', breed: 'Карликовый', ageMonths: 10, weightKg: 1.2, ownerId: 6, serviceIds: [2], notes: ''),
  const Pet(id: 17, name: 'Чижик', species: 'bird', breed: 'Канарейка', ageMonths: 8, weightKg: 0.02, ownerId: 7, serviceIds: [5], notes: ''),
  const Pet(id: 18, name: 'Лайма', species: 'dog', breed: 'Такса', ageMonths: 40, weightKg: 8.0, ownerId: 8, serviceIds: [1, 2], notes: ''),
  const Pet(id: 19, name: 'Марс', species: 'cat', breed: 'Бенгальская', ageMonths: 22, weightKg: 5.0, ownerId: 9, serviceIds: [1], notes: 'Активный'),
  const Pet(id: 20, name: 'Белка', species: 'dog', breed: 'Шпиц', ageMonths: 16, weightKg: 2.8, ownerId: 10, serviceIds: [1, 2], notes: 'Пушистая'),
  const Pet(id: 21, name: 'Тиша', species: 'cat', breed: 'Сфинкс', ageMonths: 30, weightKg: 3.5, ownerId: 1, serviceIds: [2], notes: 'Требует особого ухода'),
  const Pet(id: 22, name: 'Рыжик', species: 'dog', breed: 'Ирландский сеттер', ageMonths: 45, weightKg: 28.0, ownerId: 2, serviceIds: [1, 3], notes: ''),
];