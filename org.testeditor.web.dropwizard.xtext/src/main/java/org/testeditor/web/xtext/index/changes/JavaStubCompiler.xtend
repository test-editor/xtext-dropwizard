package org.testeditor.web.xtext.index.changes

import com.google.common.io.Files
import java.io.File
import java.io.IOException
import javax.inject.Inject
import javax.inject.Singleton
import org.eclipse.emf.common.util.URI
import org.eclipse.emf.ecore.resource.ResourceSet
import org.eclipse.xtext.builder.standalone.compiler.IJavaCompiler
import org.eclipse.xtext.builder.standalone.compiler.IJavaCompiler.CompilationResult
import org.eclipse.xtext.common.types.access.impl.IndexedJvmTypeAccess
import org.eclipse.xtext.generator.AbstractFileSystemAccess
import org.eclipse.xtext.generator.IFileSystemAccess
import org.eclipse.xtext.resource.impl.ResourceDescriptionsData
import org.slf4j.LoggerFactory
import org.testeditor.web.xtext.index.ChangeDetector
import org.testeditor.web.xtext.index.ChangedResources
import org.testeditor.web.xtext.index.ChunkedResourceDescriptionsProvider
import org.testeditor.web.xtext.index.LanguageAccessRegistry
import org.testeditor.web.xtext.index.buildutils.XtextBuilderUtils

@Singleton
class JavaStubCompiler implements ChangeDetector {

	@Inject LanguageAccessRegistry languages
	@Inject AbstractFileSystemAccess commonFileAccess
	@Inject IJavaCompiler compiler
	@Inject ChunkedResourceDescriptionsProvider resourceDescriptionsProvider
	@Inject IndexedJvmTypeAccess jvmTypeAccess
	@Inject extension XtextBuilderUtils
	
	File tempDir = Files.createTempDir
	
	static val logger = LoggerFactory.getLogger(JavaStubCompiler)
	
	
	override detectChanges(ResourceSet resourceSet, String[] paths, ChangedResources accumulatedChanges) {
		return accumulatedChanges => [
			classPath += modifiedResources.generateStubs(resourceDescriptionsProvider.data).compileStubs(classPath, paths)
			resourceDescriptionsProvider.indexResourceSet.installTypeProvider(classPath, jvmTypeAccess)
		]
	}


	private def generateStubs(Iterable<URI> sourceResourceURIs, ResourceDescriptionsData data) {
		val stubsDir = createTempDir("stubs")
		logger.info("Generating stubs into " + stubsDir.absolutePath)
		commonFileAccess.setOutputPath(IFileSystemAccess.DEFAULT_OUTPUT, stubsDir.absolutePath)
		val generateStubs = sourceResourceURIs.filter[languages.getAccess(fileExtension).linksAgainstJava]
		generateStubs.forEach [
			languages.getAccess(fileExtension).stubGenerator.doGenerateStubs(commonFileAccess, data.getResourceDescription(it))
		]
		return stubsDir
	}
	
	private def compileStubs(File stubsDir, Iterable<String> classPathEntries, Iterable<String> sourceDirs) {
		val stubsClasses = createTempDir("classes")
		compiler.setClassPath(classPathEntries)
		logger.info("Compiling stubs located in " + stubsDir.absolutePath)
		val sourcesToCompile = uniqueEntries(sourceDirs + newArrayList(stubsDir.absolutePath))
		logger.info("Compiler source roots: " + sourcesToCompile.join(','))
		val result = compiler.compile(sourcesToCompile, stubsClasses)
		switch (result) {
			case CompilationResult.SKIPPED:
				logger.info("Nothing to compile. Stubs compilation was skipped.")
			case CompilationResult.FAILED:
				logger.info("Stubs compilation finished with errors.")
			case CompilationResult.SUCCEEDED:
				logger.info("Stubs compilation successfully finished.")
		}
		return stubsClasses.absolutePath
	}

	private def createTempDir(String subDir) {
		val file = new File(tempDir, subDir)
		if (!file.mkdirs && !file.exists) throw new IOException("Failed to create directory '" + file.absolutePath + "'")
		return file
	}
	
	private def uniqueEntries(Iterable<String> paths) {
		return paths.map[new File(it).absolutePath].toSet
	}
}
