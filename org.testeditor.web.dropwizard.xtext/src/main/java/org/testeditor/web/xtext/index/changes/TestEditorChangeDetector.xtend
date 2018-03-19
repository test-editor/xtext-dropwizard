package org.testeditor.web.xtext.index.changes

import javax.inject.Inject
import org.eclipse.emf.ecore.resource.ResourceSet
import org.testeditor.web.xtext.index.ChangeDetector
import org.testeditor.web.xtext.index.ChangedResources

import static com.google.common.base.Suppliers.memoize

class TestEditorChangeDetector implements ChangeDetector {

	@Inject GitBasedChangeDetector gitChangeDetector
	@Inject GradleBuildChangeDetector gradleChangeDetector
	@Inject ChangeFilter filter

	var injectorChain = memoize[ #[gitChangeDetector, gradleChangeDetector, filter] ]

	override detectChanges(ResourceSet resourceSet, String[] paths, ChangedResources accumulatedChanges) {
		return injectorChain.get.fold(accumulatedChanges, [ changes, detector |
			detector.detectChanges(resourceSet, paths, changes)
			return changes
		])
	}

}
