//
//  RKObjectMappable.m
//  RestKit
//
//  Created by Blake Watters on 1/20/11.
//  Copyright 2011 Two Toasters. All rights reserved.
//

#import "RKObjectMappable.h"

// Return all the mapped properties of object in a dictionary
NSDictionary* RKObjectMappableGetProperties(NSObject<RKObjectMappable>*object) {
	NSDictionary* mappings = [[object class] elementToPropertyMappings];
	NSMutableDictionary* propertyNamesAndValues = [NSMutableDictionary dictionaryWithCapacity:[mappings count]];
	// Return all the properties of this model in a dictionary under their element names
	for (NSString* elementName in mappings) {
		NSString* propertyName = [mappings valueForKey:elementName];
		id propertyValue = [object valueForKey:propertyName];
		[propertyNamesAndValues setValue:propertyValue forKey:propertyName];
	}
	
	//DWT for each relationship mapping, add properties as 'mapping/item'
	
	return [NSDictionary dictionaryWithDictionary:propertyNamesAndValues];
}

// store the keys for one-many relationships
NSDictionary *serializeRelationshipsOfModel(NSObject<RKObjectMappable>*object) {
	NSMutableDictionary *elementsAndPropertyValues = [NSMutableDictionary dictionary];
	
	//NSLog(@"DWT-setRelationshipsOfModel: %@, %@",object,elements);
	NSDictionary* elementToRelationshipMappings = [[object class] elementToRelationshipMappings];
	for (NSString* elementKeyPath in elementToRelationshipMappings) {
		NSString* propertyName = [elementToRelationshipMappings objectForKey:elementKeyPath];
		
		//for each relationship mapping
		//	create a dict entry for each item in the collection
		//		set the item value to the primaryKey for the related object
		
		//get the object referred to by propertyName
		id relationshipElements = nil;
		@try {
			relationshipElements = [object valueForKey:propertyName];
			//for each item in this collection, add an entry with the primary key
			//if the property is an array, set or dict, findorcreate the related item
			if ([relationshipElements isKindOfClass:[NSArray class]] || [relationshipElements isKindOfClass:[NSSet class]]) {
				NSMutableArray *children = [NSMutableArray array];
				for (id child in relationshipElements) {
					//get the primary key for this object
					Class class = [child class];
					if ([class respondsToSelector:@selector(primaryKeyProperty)]) {
						NSString* primaryKey = [class performSelector:@selector(primaryKeyProperty)];
						id primaryKeyValue = [child valueForKey:primaryKey];
						if (primaryKeyValue != nil) {
							[children addObject:primaryKeyValue];
						} else {
							NSLog(@"ERROR: nil value for primaryKeyProperty for %@.  cannot serialize relationship", child);
						}
					} else {
						NSLog(@"ERROR: expected %@ to respond to primaryKeyProperty", child);
					}
				}
				[elementsAndPropertyValues setValue:children forKey:elementKeyPath];
			} 
		}
		@catch (NSException* e) {
			NSLog(@"Caught exception:%@ when trying valueForKey with property:%@ for object:%@", e, propertyName, object);
		}
		
	}
	return elementsAndPropertyValues;
}

// Return all the mapped properties of object in a dictionary under their element names
NSDictionary* RKObjectMappableGetPropertiesByElement(NSObject<RKObjectMappable>*object) {
	NSDictionary* mappings = [[object class] elementToPropertyMappings];
	NSMutableDictionary* elementsAndPropertyValues = [NSMutableDictionary dictionaryWithCapacity:[mappings count]];
	
	for (NSString* elementName in mappings) {
		NSString* propertyName = [mappings valueForKey:elementName];
		id propertyValue = [object valueForKey:propertyName];
		[elementsAndPropertyValues setValue:propertyValue forKey:elementName];
	}
	
	//serialize the relationships
	[elementsAndPropertyValues addEntriesFromDictionary:serializeRelationshipsOfModel(object)];
	return [NSDictionary dictionaryWithDictionary:elementsAndPropertyValues];
}

