package org.testeditor.web.xtext.index.changes

import javax.inject.Inject
import javax.inject.Named
import org.eclipse.emf.ecore.resource.ResourceSet
import org.testeditor.web.xtext.index.ChangeDetector
import org.testeditor.web.xtext.index.ChangedResources

/**
 * Filters changes detected by preceeding detectors in the chain based on an 
 * {@link IndexFilter IndexFilter}.
 * 
 * Instances of this class are intended to terminate a change detector chain.
 */
class ChangeFilter implements ChangeDetector {

	public static val String FILTER_CHANGES_FOR_INDEX = 'ChangeIndexFilter'

	@Inject @Named(FILTER_CHANGES_FOR_INDEX) extension IndexFilter filter

	override detectChanges(ResourceSet resourceSet, String[] paths, ChangedResources accumulatedChanges) {
		accumulatedChanges.modifiedResources.removeIf[!path.isRelevantForIndex]
		accumulatedChanges.deletedResources.removeIf[!path.isRelevantForIndex]
		return accumulatedChanges
	}

}
