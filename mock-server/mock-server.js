const http = require('node:http');
const crypto = require('node:crypto');

const args = process.argv.slice(2);
function arg(name, fallback) {
  const i = args.indexOf('--' + name);
  return i !== -1 && args[i + 1] ? args[i + 1] : fallback;
}

const PORT = Number(arg('port', 8080));
const ORIGIN = arg('origin', 'http://localhost:5555');
const SECRET = 'zoo-secret-not-for-production';
const ACCESS_TTL = Number(arg('ttl', 900));
const REFRESH_TTL = 60 * 60 * 24 * 7;

function b64url(buf) {
  return Buffer.from(buf).toString('base64url');
}

function sign(payload) {
  const withId = { ...payload, jti: crypto.randomUUID() };
  const body = b64url(JSON.stringify(withId));
  const mac = crypto.createHmac('sha256', SECRET).update(body).digest('base64url');
  return body + '.' + mac;
}

function verify(token) {
  if (typeof token !== 'string' || !token.includes('.')) return null;
  const [body, mac] = token.split('.');
  const expected = crypto.createHmac('sha256', SECRET).update(body).digest('base64url');
  if (mac !== expected) return null;
  let payload;
  try {
    payload = JSON.parse(Buffer.from(body, 'base64url').toString('utf8'));
  } catch {
    return null;
  }
  if (payload.exp && payload.exp * 1000 < Date.now()) return null;
  return payload;
}

let db;

function hash(password) {
  return crypto.createHash('sha256').update(password + SECRET).digest('hex');
}

function iso(y, m, d) {
  return new Date(Date.UTC(y, m - 1, d)).toISOString();
}

function push(collection, obj) {
  db.seq[collection] = (db.seq[collection] || 0) + 1;
  const id = db.seq[collection];
  db[collection].push({ id, ...obj, createdAt: new Date().toISOString(), deletedAt: null });
  return id;
}

function seed() {
  db = {
    seq: {},
    clinics: [],
    owners: [],
    services: [],
    pets: [],
    passports: [],
    visits: [],
    users: [],
    refreshTokens: new Set(),
  };

  const c1 = push('clinics', {
    name: 'Зоосалон Центр',
    address: 'ул. Пушкина, 10',
    phone: '+7 495 111-11-11',
    city: 'Москва',
    slotsTotal: 5,
    slotsAvailable: 5,
  });
  const c2 = push('clinics', {
    name: 'Зоосалон Север',
    address: 'пр. Мира, 25',
    phone: '+7 495 222-22-22',
    city: 'Москва',
    slotsTotal: 2,
    slotsAvailable: 0,
  });
  const c3 = push('clinics', {
    name: 'Зоосалон Невский',
    address: 'Невский пр., 40',
    phone: '+7 812 333-33-33',
    city: 'Санкт-Петербург',
    slotsTotal: 4,
    slotsAvailable: 4,
  });

  const o1 = push('owners', {
    lastName: 'Иванов', firstName: 'Иван', phone: '+7 900 100-10-01',
    email: 'ivanov@example.com', city: 'Москва', country: 'Россия',
  });
  const o2 = push('owners', {
    lastName: 'Петрова', firstName: 'Анна', phone: '+7 900 100-10-02',
    email: 'petrova@example.com', city: 'Москва', country: 'Россия',
  });
  const o3 = push('owners', {
    lastName: 'Сидоров', firstName: 'Пётр', phone: '+7 900 100-10-03',
    email: 'sidorov@example.com', city: 'Санкт-Петербург', country: 'Россия',
  });
  const o4 = push('owners', {
    lastName: 'Козлова', firstName: 'Мария', phone: '+7 900 100-10-04',
    email: 'kozlova@example.com', city: 'Казань', country: 'Россия',
  });
  const o5 = push('owners', {
    lastName: 'Новиков', firstName: 'Алексей', phone: '+7 900 100-10-05',
    email: 'novikov@example.com', city: 'Москва', country: 'Россия',
  });

  const s1 = push('services', { name: 'Стрижка', description: 'Гигиеническая стрижка', price: 1500, clinicId: c1 });
  const s2 = push('services', { name: 'Мытьё', description: 'Купание с шампунем', price: 800, clinicId: c1 });
  const s3 = push('services', { name: 'Чистка ушей', description: 'Гигиена ушей', price: 400, clinicId: c1 });
  const s4 = push('services', { name: 'Стрижка', description: 'Полная стрижка', price: 1800, clinicId: c2 });
  const s5 = push('services', { name: 'Вычёсывание', description: 'Удаление колтунов', price: 1200, clinicId: c2 });
  const s6 = push('services', { name: 'SPA', description: 'Комплексный уход', price: 3500, clinicId: c3 });
  const s7 = push('services', { name: 'Стрижка когтей', description: 'Подрезка когтей', price: 300, clinicId: c3 });

  const petsSeed = [
    ['Барсик', 'cat', 'Британский', 'CHIP-0001', 24, 4.5, c1, [o1], [s1, s2], ''],
    ['Мурка', 'cat', 'Сиамская', 'CHIP-0002', 18, 3.2, c1, [o2], [s2, s3], ''],
    ['Рекс', 'dog', 'Лабрадор', 'CHIP-0003', 36, 28.0, c1, [o1, o2], [s1], 'Аллергия на курицу'],
    ['Шарик', 'dog', 'Дворняга', 'CHIP-0004', 48, 15.0, c2, [o3], [s4, s5], ''],
    ['Тимоша', 'cat', 'Мейн-кун', 'CHIP-0005', 12, 5.1, c2, [o4], [s4], ''],
    ['Люси', 'dog', 'Пудель', 'CHIP-0006', 30, 8.0, c3, [o5], [s6, s7], ''],
    ['Васька', 'cat', 'Дворняга', 'CHIP-0007', 60, 4.0, c3, [o3], [s7], ''],
    ['Джесси', 'dog', 'Хаски', 'CHIP-0008', 20, 22.0, c1, [o5], [s1, s2], ''],
    ['Нюша', 'cat', 'Персидская', 'CHIP-0009', 40, 3.8, c2, [o2], [s5], ''],
    ['Боня', 'dog', 'Корги', 'CHIP-0010', 16, 12.0, c3, [o4], [s6], ''],
    ['Пушок', 'cat', 'Рэгдолл', 'CHIP-0011', 8, 2.9, c1, [o1], [s3], ''],
    ['Грей', 'dog', 'Хаски', 'CHIP-0012', 28, 25.0, c2, [o3], [s4], ''],
  ];

  for (const [name, species, breed, chipNumber, ageMonths, weightKg, clinicId, ownerIds, serviceIds, notes] of petsSeed) {
    const petId = push('pets', {
      name, species, breed, chipNumber, ageMonths, weightKg, clinicId, ownerIds, serviceIds, notes,
    });
    push('passports', {
      petId,
      number: 'PP-' + String(petId).padStart(6, '0'),
      microchip: chipNumber,
      issuedAt: iso(2025, 1, petId),
    });
  }

  push('visits', {
    petId: 4,
    clinicId: c2,
    issuedAt: new Date(Date.now() - 2 * 86400000).toISOString(),
    dueAt: new Date(Date.now() + 5 * 86400000).toISOString(),
    returnedAt: null,
  });

  push('users', {
    username: 'admin', passwordHash: hash('admin123'),
    fullName: 'Администратор', email: 'admin@zoo.local', role: 'admin',
  });
}

function slimClinic(id) {
  const c = db.clinics.find((x) => x.id === id);
  return c ? { id: c.id, name: c.name } : null;
}

function expandOwner(o) {
  return {
    id: o.id,
    lastName: o.lastName,
    firstName: o.firstName,
    fullName: `${o.lastName} ${o.firstName}`,
    phone: o.phone,
    email: o.email,
    city: o.city,
    country: o.country,
    createdAt: o.createdAt,
    deletedAt: o.deletedAt,
  };
}

function expandService(s) {
  return {
    id: s.id,
    name: s.name,
    description: s.description,
    price: s.price,
    clinicId: s.clinicId,
    createdAt: s.createdAt,
    deletedAt: s.deletedAt,
  };
}

function expandClinic(c) {
  return {
    id: c.id,
    name: c.name,
    address: c.address,
    phone: c.phone,
    city: c.city,
    slotsTotal: c.slotsTotal,
    slotsAvailable: c.slotsAvailable,
    createdAt: c.createdAt,
    deletedAt: c.deletedAt,
  };
}

function expandPet(p) {
  return {
    id: p.id,
    name: p.name,
    species: p.species,
    breed: p.breed,
    chipNumber: p.chipNumber,
    ageMonths: p.ageMonths,
    weightKg: p.weightKg,
    clinic: slimClinic(p.clinicId),
    clinicId: p.clinicId,
    owners: (p.ownerIds || [])
      .map((id) => db.owners.find((o) => o.id === id))
      .filter(Boolean)
      .map((o) => ({ id: o.id, lastName: o.lastName, firstName: o.firstName, fullName: `${o.lastName} ${o.firstName}` })),
    ownerIds: p.ownerIds || [],
    services: (p.serviceIds || [])
      .map((id) => db.services.find((s) => s.id === id))
      .filter(Boolean)
      .map((s) => ({ id: s.id, name: s.name })),
    serviceIds: p.serviceIds || [],
    notes: p.notes || '',
    createdAt: p.createdAt,
    deletedAt: p.deletedAt,
  };
}

function expandPassport(pp) {
  return {
    id: pp.id,
    petId: pp.petId,
    number: pp.number,
    microchip: pp.microchip,
    issuedAt: pp.issuedAt,
    createdAt: pp.createdAt,
    deletedAt: pp.deletedAt,
  };
}

function expandVisit(v) {
  const pet = db.pets.find((p) => p.id === v.petId);
  const clinic = db.clinics.find((c) => c.id === v.clinicId);
  let status = 'active';
  if (v.returnedAt) status = 'returned';
  else if (new Date(v.dueAt) < new Date()) status = 'overdue';
  return {
    id: v.id,
    pet: pet ? { id: pet.id, name: pet.name } : null,
    petId: v.petId,
    clinic: clinic ? { id: clinic.id, name: clinic.name } : null,
    clinicId: v.clinicId,
    issuedAt: v.issuedAt,
    dueAt: v.dueAt,
    returnedAt: v.returnedAt,
    status,
    deletedAt: v.deletedAt,
  };
}

function expandUser(u) {
  return { id: u.id, username: u.username, fullName: u.fullName, email: u.email, role: u.role };
}

const EXPANDERS = {
  pets: expandPet,
  owners: expandOwner,
  services: expandService,
  clinics: expandClinic,
  passports: expandPassport,
  visits: expandVisit,
};

function searchableText(collection, item) {
  switch (collection) {
    case 'pets': return [item.name, item.breed, item.chipNumber, item.species].join(' ');
    case 'owners': return [item.lastName, item.firstName, item.email, item.phone, item.city].join(' ');
    case 'services': return [item.name, item.description].join(' ');
    case 'clinics': return [item.name, item.city, item.address].join(' ');
    case 'passports': return [item.number, item.microchip].join(' ');
    default: return '';
  }
}

function applyFilters(collection, rows, q) {
  let result = rows;
  if (q.search) {
    const needle = String(q.search).toLowerCase();
    result = result.filter((x) => searchableText(collection, x).toLowerCase().includes(needle));
  }
  if (collection === 'pets') {
    if (q.species) result = result.filter((p) => p.species === q.species);
    if (q.ownerId) result = result.filter((p) => (p.ownerIds || []).includes(Number(q.ownerId)));
    if (q.clinicId) result = result.filter((p) => p.clinicId === Number(q.clinicId));
    if (q.ageFrom) result = result.filter((p) => p.ageMonths >= Number(q.ageFrom));
    if (q.ageTo) result = result.filter((p) => p.ageMonths <= Number(q.ageTo));
  }
  if (collection === 'owners') {
    if (q.city) result = result.filter((o) => o.city === q.city);
    if (q.country) result = result.filter((o) => o.country === q.country);
  }
  if (collection === 'services') {
    if (q.clinicId) result = result.filter((s) => s.clinicId === Number(q.clinicId));
  }
  if (collection === 'clinics') {
    if (q.city) result = result.filter((c) => c.city === q.city);
  }
  if (collection === 'passports') {
    if (q.petId) result = result.filter((p) => p.petId === Number(q.petId));
  }
  if (collection === 'visits') {
    if (q.petId) result = result.filter((v) => v.petId === Number(q.petId));
    if (q.clinicId) result = result.filter((v) => v.clinicId === Number(q.clinicId));
  }
  return result;
}

function applySort(rows, sort) {
  if (!sort) return rows;
  const [field, dirRaw] = String(sort).split(',');
  const dir = (dirRaw || 'asc').toLowerCase() === 'desc' ? -1 : 1;
  return [...rows].sort((a, b) => {
    const av = a[field];
    const bv = b[field];
    if (av == null && bv == null) return 0;
    if (av == null) return 1;
    if (bv == null) return -1;
    if (typeof av === 'number' && typeof bv === 'number') return (av - bv) * dir;
    return String(av).localeCompare(String(bv), 'ru') * dir;
  });
}

function paginate(rows, q) {
  const page = Math.max(1, Number(q.page) || 1);
  const size = Math.min(100, Math.max(1, Number(q.size) || 10));
  const total = rows.length;
  const totalPages = Math.max(1, Math.ceil(total / size));
  return {
    items: rows.slice((page - 1) * size, page * size),
    page,
    size,
    total,
    totalPages,
  };
}

function validate(collection, body, id = null) {
  const e = {};
  const str = (v) => (typeof v === 'string' ? v.trim() : '');

  if (collection === 'pets') {
    if (!str(body.name)) e.name = 'Укажите кличку';
    if (!str(body.chipNumber)) e.chipNumber = 'Укажите номер чипа';
    else {
      const dup = db.pets.find(
        (p) => p.chipNumber === str(body.chipNumber) && p.id !== id && !p.deletedAt
      );
      if (dup) e.chipNumber = 'Питомец с таким номером чипа уже существует';
    }
    if (body.clinicId == null || !db.clinics.find((c) => c.id === Number(body.clinicId) && !c.deletedAt)) {
      e.clinicId = 'Филиал не найден';
    }
    const age = Number(body.ageMonths);
    if (!Number.isInteger(age) || age < 0) e.ageMonths = 'Возраст — целое число месяцев ≥ 0';
  }

  if (collection === 'owners') {
    if (!str(body.lastName)) e.lastName = 'Укажите фамилию';
    if (!str(body.firstName)) e.firstName = 'Укажите имя';
    if (!str(body.email)) e.email = 'Укажите email';
    else if (!/^[\w.+-]+@[\w-]+\.[\w.-]+$/.test(str(body.email))) e.email = 'Некорректный email';
    else {
      const dup = db.owners.find(
        (o) => o.email === str(body.email) && o.id !== id && !o.deletedAt
      );
      if (dup) e.email = 'Владелец с таким email уже существует';
    }
  }

  if (collection === 'services') {
    if (!str(body.name)) e.name = 'Укажите название услуги';
    if (body.clinicId == null || !db.clinics.find((c) => c.id === Number(body.clinicId) && !c.deletedAt)) {
      e.clinicId = 'Филиал не найден';
    }
  }

  if (collection === 'clinics') {
    if (!str(body.name)) e.name = 'Укажите название филиала';
    const slots = Number(body.slotsTotal);
    if (body.slotsTotal != null && (!Number.isInteger(slots) || slots < 0)) {
      e.slotsTotal = 'Число мест — целое ≥ 0';
    }
  }

  if (collection === 'passports') {
    if (!str(body.number)) e.number = 'Укажите номер паспорта';
    else {
      const dup = db.passports.find(
        (p) => p.number === str(body.number) && p.id !== id && !p.deletedAt
      );
      if (dup) e.number = 'Паспорт с таким номером уже существует';
    }
    if (body.petId == null || !db.pets.find((p) => p.id === Number(body.petId) && !p.deletedAt)) {
      e.petId = 'Питомец не найден';
    } else if (id == null) {
      const existing = db.passports.find(
        (p) => p.petId === Number(body.petId) && !p.deletedAt
      );
      if (existing) e.petId = 'У питомца уже есть паспорт';
    }
  }

  return e;
}

function normalize(collection, body) {
  const num = (v) => (v == null || v === '' ? null : Number(v));
  const str = (v) => (v == null ? '' : String(v).trim());
  const ids = (v) => (Array.isArray(v) ? v.map(Number).filter((n) => Number.isInteger(n)) : []);

  switch (collection) {
    case 'pets':
      return {
        name: str(body.name),
        species: str(body.species) || 'cat',
        breed: str(body.breed),
        chipNumber: str(body.chipNumber),
        ageMonths: num(body.ageMonths) ?? 0,
        weightKg: Number(body.weightKg) || 0,
        clinicId: num(body.clinicId),
        ownerIds: ids(body.ownerIds),
        serviceIds: ids(body.serviceIds),
        notes: str(body.notes),
      };
    case 'owners':
      return {
        lastName: str(body.lastName),
        firstName: str(body.firstName),
        phone: str(body.phone),
        email: str(body.email),
        city: str(body.city),
        country: str(body.country),
      };
    case 'services':
      return {
        name: str(body.name),
        description: str(body.description),
        price: Number(body.price) || 0,
        clinicId: num(body.clinicId),
      };
    case 'clinics': {
      const slotsTotal = num(body.slotsTotal) ?? 0;
      return {
        name: str(body.name),
        address: str(body.address),
        phone: str(body.phone),
        city: str(body.city),
        slotsTotal,
      };
    }
    case 'passports':
      return {
        petId: num(body.petId),
        number: str(body.number),
        microchip: str(body.microchip),
        issuedAt: body.issuedAt || new Date().toISOString(),
      };
    default:
      return { ...body };
  }
}

function cors(res) {
  res.setHeader('Access-Control-Allow-Origin', ORIGIN);
  res.setHeader('Access-Control-Allow-Methods', 'GET, POST, PUT, PATCH, DELETE, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type, Authorization');
  res.setHeader('Access-Control-Max-Age', '86400');
  res.setHeader('Vary', 'Origin');
}

function send(res, status, payload) {
  cors(res);
  if (payload === undefined || status === 204) {
    res.writeHead(204);
    res.end();
    return;
  }
  const body = JSON.stringify(payload, null, 2);
  res.writeHead(status, {
    'Content-Type': 'application/json; charset=utf-8',
    'Content-Length': Buffer.byteLength(body),
  });
  res.end(body);
}

function fail(res, status, message) {
  send(res, status, { message });
}

async function readBody(req) {
  const chunks = [];
  for await (const chunk of req) chunks.push(chunk);
  if (!chunks.length) return {};
  try {
    return JSON.parse(Buffer.concat(chunks).toString('utf8'));
  } catch {
    return null;
  }
}

function currentUser(req) {
  const header = req.headers['authorization'] || '';
  if (!header.startsWith('Bearer ')) return null;
  const payload = verify(header.slice(7));
  if (!payload || payload.type !== 'access') return null;
  return db.users.find((u) => u.id === payload.sub && !u.deletedAt) || null;
}

const ROLE_LEVEL = { reader: 1, librarian: 2, admin: 3 };

function requireRole(res, user, minRole) {
  if (!user) {
    fail(res, 401, 'Требуется аутентификация');
    return false;
  }
  if (ROLE_LEVEL[user.role] < ROLE_LEVEL[minRole]) {
    fail(res, 403, `Операция доступна начиная с роли «${minRole}»`);
    return false;
  }
  return true;
}

const COLLECTIONS = ['pets', 'owners', 'services', 'clinics', 'passports', 'visits'];

async function handle(req, res, url) {
  const q = Object.fromEntries(url.searchParams.entries());
  const path = url.pathname.replace(/\/+$/, '') || '/';
  const method = req.method.toUpperCase();
  const user = currentUser(req);

  if (q.__fail) {
    return fail(res, Number(q.__fail), 'Ошибка вызвана намеренно параметром __fail');
  }

  if (path === '/api/__reset' && method === 'POST') {
    seed();
    return send(res, 200, { message: 'Данные восстановлены в исходное состояние' });
  }

  if (path === '/api/__health' && method === 'GET') {
    return send(res, 200, { status: 'ok', time: new Date().toISOString() });
  }

  if (path === '/api/auth/login' && method === 'POST') {
    const body = await readBody(req);
    if (!body) return fail(res, 400, 'Тело запроса не является корректным JSON');
    const found = db.users.find(
      (u) => u.username === String(body.username || '').trim() && !u.deletedAt
    );
    if (!found || found.passwordHash !== hash(String(body.password || ''))) {
      return fail(res, 401, 'Неверный логин или пароль');
    }
    const now = Math.floor(Date.now() / 1000);
    const accessToken = sign({ sub: found.id, role: found.role, type: 'access', exp: now + ACCESS_TTL });
    const refreshToken = sign({ sub: found.id, type: 'refresh', exp: now + REFRESH_TTL });
    db.refreshTokens.add(refreshToken);
    return send(res, 200, {
      accessToken,
      refreshToken,
      expiresIn: ACCESS_TTL,
      user: expandUser(found),
    });
  }

  if (path === '/api/auth/refresh' && method === 'POST') {
    const body = await readBody(req);
    const token = body && body.refreshToken;
    const payload = verify(token);
    if (!payload || payload.type !== 'refresh' || !db.refreshTokens.has(token)) {
      return fail(res, 401, 'Токен обновления недействителен');
    }
    const found = db.users.find((u) => u.id === payload.sub);
    if (!found) return fail(res, 401, 'Пользователь не найден');
    db.refreshTokens.delete(token);
    const now = Math.floor(Date.now() / 1000);
    const accessToken = sign({ sub: found.id, role: found.role, type: 'access', exp: now + ACCESS_TTL });
    const refreshToken = sign({ sub: found.id, type: 'refresh', exp: now + REFRESH_TTL });
    db.refreshTokens.add(refreshToken);
    return send(res, 200, { accessToken, refreshToken, expiresIn: ACCESS_TTL, user: expandUser(found) });
  }

  if (path === '/api/auth/me' && method === 'GET') {
    if (!user) return fail(res, 401, 'Требуется аутентификация');
    return send(res, 200, expandUser(user));
  }

  if (path === '/api/auth/logout' && method === 'POST') {
    const body = await readBody(req);
    if (body && body.refreshToken) db.refreshTokens.delete(body.refreshToken);
    return send(res, 204);
  }

  if (path === '/api/visits' && method === 'POST') {
    if (!requireRole(res, user, 'librarian')) return;
    const body = await readBody(req);
    if (!body) return fail(res, 400, 'Тело запроса не является корректным JSON');

    const errors = {};
    const pet = db.pets.find((p) => p.id === Number(body.petId) && !p.deletedAt);
    const clinic = db.clinics.find((c) => c.id === Number(body.clinicId) && !c.deletedAt);
    if (!pet) errors.petId = 'Питомец не найден';
    if (!clinic) errors.clinicId = 'Филиал не найден';
    const days = Number(body.days || 1);
    if (!Number.isInteger(days) || days < 1 || days > 90) errors.days = 'Срок от 1 до 90 дней';
    if (Object.keys(errors).length) return send(res, 422, { message: 'Ошибка валидации', errors });

    if (clinic.slotsAvailable < 1) {
      return fail(res, 409, 'Нет свободных мест в филиале для заселения');
    }

    const active = db.visits.find(
      (v) => v.petId === pet.id && !v.returnedAt && !v.deletedAt
    );
    if (active) {
      return fail(res, 409, 'Питомец уже заселён и ещё не выписан');
    }

    const issuedAt = new Date();
    const dueAt = new Date(issuedAt.getTime() + days * 86400000);
    const id = push('visits', {
      petId: pet.id,
      clinicId: clinic.id,
      issuedAt: issuedAt.toISOString(),
      dueAt: dueAt.toISOString(),
      returnedAt: null,
    });
    clinic.slotsAvailable -= 1;
    return send(res, 201, expandVisit(db.visits.find((v) => v.id === id)));
  }

  let m = path.match(/^\/api\/visits\/(\d+)\/return$/);
  if (m && method === 'POST') {
    if (!requireRole(res, user, 'librarian')) return;
    const visit = db.visits.find((v) => v.id === Number(m[1]) && !v.deletedAt);
    if (!visit) return fail(res, 404, 'Заселение не найдено');
    if (visit.returnedAt) return fail(res, 409, 'Заселение уже закрыто');
    visit.returnedAt = new Date().toISOString();
    const clinic = db.clinics.find((c) => c.id === visit.clinicId);
    if (clinic) clinic.slotsAvailable = Math.min(clinic.slotsTotal, clinic.slotsAvailable + 1);
    return send(res, 200, expandVisit(visit));
  }

  m = path.match(/^\/api\/([a-z]+)(?:\/(\d+))?(?:\/(restore))?$/);
  const bulk = path.match(/^\/api\/([a-z]+)\/bulk-delete$/);

  if (bulk && method === 'POST') {
    const collection = bulk[1];
    if (!COLLECTIONS.includes(collection)) return fail(res, 404, 'Ресурс не найден');
    if (!requireRole(res, user, 'librarian')) return;
    const body = await readBody(req);
    const ids = Array.isArray(body && body.ids) ? body.ids.map(Number) : [];
    if (!ids.length) {
      return send(res, 422, { message: 'Ошибка валидации', errors: { ids: 'Передайте непустой список идентификаторов' } });
    }
    let deleted = 0;
    for (const row of db[collection]) {
      if (ids.includes(row.id) && !row.deletedAt) {
        row.deletedAt = new Date().toISOString();
        deleted += 1;
      }
    }
    return send(res, 200, { deleted });
  }

  if (m) {
    const collection = m[1];
    const id = m[2] ? Number(m[2]) : null;
    const action = m[3] || null;
    if (!COLLECTIONS.includes(collection)) return fail(res, 404, 'Ресурс не найден');
    const expand = EXPANDERS[collection];

    if (action === 'restore' && method === 'POST') {
      if (!requireRole(res, user, 'librarian')) return;
      const row = db[collection].find((x) => x.id === id);
      if (!row) return fail(res, 404, 'Объект не найден');
      row.deletedAt = null;
      return send(res, 200, expand(row));
    }

    if (id === null && method === 'GET') {
      let rows = db[collection];
      if (q.includeDeleted !== 'true') rows = rows.filter((x) => !x.deletedAt);
      rows = applyFilters(collection, rows, q);
      rows = applySort(rows, q.sort);
      const page = paginate(rows, q);
      return send(res, 200, { ...page, items: page.items.map(expand) });
    }

    if (id !== null && method === 'GET') {
      const row = db[collection].find((x) => x.id === id && (q.includeDeleted === 'true' || !x.deletedAt));
      if (!row) return fail(res, 404, 'Объект не найден');
      return send(res, 200, expand(row));
    }

    if (id === null && method === 'POST') {
      if (!requireRole(res, user, 'librarian')) return;
      if (collection === 'visits') return fail(res, 404, 'Используйте POST /api/visits');
      const body = await readBody(req);
      if (!body) return fail(res, 400, 'Тело запроса не является корректным JSON');
      const errors = validate(collection, body);
      if (Object.keys(errors).length) return send(res, 422, { message: 'Ошибка валидации', errors });
      const data = normalize(collection, body);
      const newId = push(collection, data);
      const row = db[collection].find((x) => x.id === newId);
      if (collection === 'clinics') {
        row.slotsAvailable = row.slotsTotal;
      }
      return send(res, 201, expand(row));
    }

    if (id !== null && (method === 'PUT' || method === 'PATCH')) {
      if (!requireRole(res, user, 'librarian')) return;
      const row = db[collection].find((x) => x.id === id && !x.deletedAt);
      if (!row) return fail(res, 404, 'Объект не найден');
      const body = await readBody(req);
      if (!body) return fail(res, 400, 'Тело запроса не является корректным JSON');
      const merged = method === 'PATCH' ? { ...row, ...body } : body;
      const errors = validate(collection, merged, id);
      if (Object.keys(errors).length) return send(res, 422, { message: 'Ошибка валидации', errors });
      const prevSlots = collection === 'clinics' ? row.slotsTotal : null;
      Object.assign(row, normalize(collection, merged));
      if (collection === 'clinics' && prevSlots != null) {
        const used = prevSlots - (row.slotsAvailable ?? 0);
        row.slotsAvailable = Math.max(0, row.slotsTotal - used);
      }
      return send(res, 200, expand(row));
    }

    if (id !== null && method === 'DELETE') {
      const hard = q.hard === 'true';
      if (!requireRole(res, user, hard ? 'admin' : 'librarian')) return;
      const index = db[collection].findIndex((x) => x.id === id);
      if (index === -1) return fail(res, 404, 'Объект не найден');
      if (hard) {
        if (collection === 'clinics') {
          const linked = db.pets.some((p) => p.clinicId === id && !p.deletedAt);
          if (linked) return fail(res, 409, 'У филиала есть связанные питомцы');
        }
        if (collection === 'owners') {
          const linked = db.pets.some((p) => (p.ownerIds || []).includes(id) && !p.deletedAt);
          if (linked) return fail(res, 409, 'У владельца есть связанные питомцы');
        }
        db[collection].splice(index, 1);
      } else {
        db[collection][index].deletedAt = new Date().toISOString();
      }
      return send(res, 204);
    }
  }

  return fail(res, 404, `Адрес ${method} ${path} не обслуживается`);
}

seed();

const server = http.createServer(async (req, res) => {
  const url = new URL(req.url, `http://${req.headers.host || 'localhost'}`);
  if (req.method === 'OPTIONS') {
    cors(res);
    res.writeHead(204);
    return res.end();
  }
  const delay = Number(url.searchParams.get('__delay') || 0);
  if (delay > 0) await new Promise((r) => setTimeout(r, Math.min(delay, 10000)));
  const started = Date.now();
  try {
    await handle(req, res, url);
  } catch (err) {
    console.error(err);
    if (!res.headersSent) fail(res, 500, 'Внутренняя ошибка сервера: ' + err.message);
  }
  console.log(
    `${req.method.padEnd(6)} ${url.pathname}${url.search}  → ${res.statusCode}  ${Date.now() - started} мс`
  );
});

server.listen(PORT, () => {
  console.log('');
  console.log('  API «Зоосалон»');
  console.log(`  Адрес:              http://localhost:${PORT}/api`);
  console.log(`  Разрешённый источник: ${ORIGIN}`);
  console.log(`  Срок жизни токена:  ${ACCESS_TTL} с`);
  console.log('');
  console.log('  Учётные записи:  admin/admin123');
  console.log('  Сброс данных:    POST /api/__reset');
  console.log('  Задержка ответа: любой запрос с ?__delay=1500');
  console.log('  Ошибка по требованию: любой запрос с ?__fail=500');
  console.log('');
});
