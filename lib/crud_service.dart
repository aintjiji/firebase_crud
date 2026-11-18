import 'package:cloud_firestore/cloud_firestore.dart';

class CrudService {
  final CollectionReference items =
  FirebaseFirestore.instance.collection('items');
 
Future <void> addItem(String name, int quantity){
//create
  return items.add({
    'name': name,
    'quantity': quantity,
    'isFavorite': false,
    'createdAt': Timestamp.now(),
  });
}
//read
Stream<QuerySnapshot> getItems(){
  return items.orderBy('createdAt',descending: true).snapshots();
}

//update
Future<void> updateItem(String id,String name, int quantity){
  return items.doc(id).update({
    'name':name,
    'quantity': quantity,
  });
}


//delete
Future<void> deleteItems (String id, String name,String quantity){
  return items.doc(id).delete();
}

//favorite
Future<void> toggleFavorite(String id, bool current) {
  return items.doc(id).update({'isFavorite': !current});
}

  void deleteItem(String id) {}
}