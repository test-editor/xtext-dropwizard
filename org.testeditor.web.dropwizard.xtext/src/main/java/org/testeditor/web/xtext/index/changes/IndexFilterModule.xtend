package org.testeditor.web.xtext.index.changes

import com.google.inject.PrivateModule
import com.google.inject.Provides
import com.google.inject.name.Names
import javax.inject.Inject

/**
 * Private Guice module provided as default / sample for wiring up an index change filter.
 * 
 * In particular, installing this module exposes a binding for 
 * {@link org.testeditor.web.xtext.index.changes.ChangeFilter ChangeFilter},
 * which has its {@link org.testeditor.web.xtext.index.changes.IndexFilter IndexFilter}
 * wired to a {@link org.testeditor.web.xtext.index.changes.LogicalAndBasedIndexFilter LogicalAndBasedIndexFilter},
 * which in turn combines a {@link org.testeditor.web.xtext.index.changes.SearchPathBasedIndexFilter SearchPathBasedIndexFilter}
 * and a {@link org.testeditor.web.xtext.index.changes.LanguageExtensionBasedIndexFilter LanguageExtensionBasedIndexFilter}.
 */
class IndexFilterModule extends PrivateModule {

	override protected configure() {
		bind(IndexFilter).annotatedWith(Names.named(ChangeFilter.FILTER_CHANGES_FOR_INDEX)).to(LogicalAndBasedIndexFilter)
		expose(IndexFilter).annotatedWith(Names.named(ChangeFilter.FILTER_CHANGES_FOR_INDEX))
	}

	@Provides
	@Inject
	def Iterable<IndexFilter> filters(SearchPathBasedIndexFilter searchPathFilter, LanguageExtensionBasedIndexFilter languageFilter) {
		return #[searchPathFilter, languageFilter]
	}
}
