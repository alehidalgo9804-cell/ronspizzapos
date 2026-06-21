import 'figma_models.dart';

const List<TableInfo> initialTables = [
  // Mesas individuales
  TableInfo(id: '5', number: '5', status: TableStatus.available),
  TableInfo(id: '6', number: '6', status: TableStatus.available),
  TableInfo(id: '7', number: '7', status: TableStatus.available),
  TableInfo(id: '8', number: '8', status: TableStatus.available),
  TableInfo(id: '9', number: '9', status: TableStatus.available),
  // Mesas combinadas
  TableInfo(id: '12', number: '1 y 2', status: TableStatus.available),
  TableInfo(id: '34', number: '3 y 4', status: TableStatus.available),
];

const List<CategoryData> categories = [
  CategoryData(
    id: 'pizzas',
    code: '01',
    name: 'Pizzas',
    image: 'assets/images/categories/pizzas.jpg',
  ),
  CategoryData(
    id: 'hamburgers',
    code: '02',
    name: 'Hamburguesas',
    image: 'assets/images/categories/hamburguesas.jpg',
  ),
  CategoryData(
    id: 'wings',
    code: '03',
    name: 'Alitas',
    image: 'assets/images/categories/alitas.jpeg',
  ),
  CategoryData(
    id: 'boneless',
    code: '04',
    name: 'Boneless',
    image: 'assets/images/categories/boneless.jpeg',
  ),
  CategoryData(
    id: 'spaghetti',
    code: '06',
    name: 'Spaghetti',
    image: 'assets/images/categories/spaghetti.jpg',
  ),
  CategoryData(
    id: 'sauces',
    code: '07',
    name: 'Salsas',
    image: 'assets/images/categories/salsas.jpg',
  ),
  CategoryData(
    id: 'drinks',
    code: '08',
    name: 'Bebidas',
    image:
        'https://images.unsplash.com/photo-1551024709-8f23befc6cf7?auto=format&fit=crop&w=800&q=80',
  ),
  CategoryData(
    id: 'extras',
    code: '10',
    name: 'Extras',
    image: '',
  ),
  CategoryData(
    id: 'menu_estadio',
    code: 'ME',
    name: 'MENU ESTADIO',
    image: 'assets/images/categories/menu_estadio.jpg',
  ),
];

const List<ProductData> products = [
  ProductData(
      id: 'b1',
      name: 'Boneless Bites (8pc)',
      price: 7.99,
      categoryId: 'boneless'),
  ProductData(
      id: 'b2',
      name: 'Boneless Bites (16pc)',
      price: 13.99,
      categoryId: 'boneless'),
  ProductData(id: 'c1', name: 'Papas', price: 69, categoryId: 'complements'),
  ProductData(id: 'c2', name: 'Aros', price: 69, categoryId: 'complements'),
  ProductData(id: 'c3', name: 'Quesitos', price: 69, categoryId: 'complements'),
  ProductData(
      id: 'c4', name: 'Panes de ajo', price: 69, categoryId: 'complements'),
  ProductData(id: 'c5', name: 'Ensalada', price: 69, categoryId: 'complements'),
  ProductData(
    id: 'sa1',
    name: 'Ligera',
    price: 20,
    categoryId: 'sauces',
    image: 'assets/images/sauces/mediana_ligera.jpg',
  ),
  ProductData(
    id: 'sa2',
    name: 'Mediana',
    price: 20,
    categoryId: 'sauces',
    image: 'assets/images/sauces/mediana_ligera.jpg',
  ),
  ProductData(
    id: 'sa3',
    name: 'Caliente',
    price: 20,
    categoryId: 'sauces',
    image: 'assets/images/sauces/caliente_terrible.jpg',
  ),
  ProductData(
    id: 'sa4',
    name: 'Terrible',
    price: 20,
    categoryId: 'sauces',
    image: 'assets/images/sauces/caliente_terrible.jpg',
  ),
  ProductData(
    id: 'sa5',
    name: 'BBQ',
    price: 20,
    categoryId: 'sauces',
    image: 'assets/images/sauces/bbq_tamarindo.jpg',
  ),
  ProductData(
    id: 'sa6',
    name: 'Tamarindo',
    price: 20,
    categoryId: 'sauces',
    image: 'assets/images/sauces/bbq_tamarindo.jpg',
  ),
  ProductData(
    id: 'sa7',
    name: 'Mango habanero',
    price: 20,
    categoryId: 'sauces',
    image: 'assets/images/sauces/mango_habanero.jpg',
  ),
  ProductData(
    id: 'sa8',
    name: 'Ranch',
    price: 20,
    categoryId: 'sauces',
    image: 'assets/images/sauces/ranch.jpg',
  ),
  ProductData(
    id: 'sa9',
    name: 'Salsa de tomate',
    price: 20,
    categoryId: 'sauces',
    image: 'assets/images/sauces/salsa_tomate_nueva.png',
  ),
  ProductData(id: 'd1', name: 'Coca Cola', price: 2.49, categoryId: 'drinks'),
  ProductData(id: 'd2', name: 'Sprite', price: 2.49, categoryId: 'drinks'),
  ProductData(
      id: 'me_pizza_grande',
      name: 'Pizza grande',
      price: 279,
      categoryId: 'menu_estadio'),
  ProductData(
      id: 'me_pizza_rebanada',
      name: 'Pizza rebanada',
      price: 50,
      categoryId: 'menu_estadio'),
  ProductData(
      id: 'me_pizza_mini',
      name: 'Pizza mini',
      price: 99,
      categoryId: 'menu_estadio'),
  ProductData(
      id: 'me_alitas',
      name: 'Alitas',
      price: 149,
      categoryId: 'menu_estadio'),
  ProductData(
      id: 'me_boneless',
      name: 'Boneless',
      price: 149,
      categoryId: 'menu_estadio'),
  ProductData(
      id: 'me_papas', name: 'Papas', price: 69, categoryId: 'menu_estadio'),
  ProductData(
      id: 'me_aros', name: 'Aros', price: 69, categoryId: 'menu_estadio'),
  ProductData(
      id: 'me_quesitos',
      name: 'Quesitos',
      price: 69,
      categoryId: 'menu_estadio'),
  ProductData(
      id: 'me_panes_ajo',
      name: 'Panes de ajo',
      price: 69,
      categoryId: 'menu_estadio'),
];
