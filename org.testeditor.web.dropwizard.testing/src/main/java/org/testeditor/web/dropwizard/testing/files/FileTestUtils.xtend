package org.testeditor.web.dropwizard.testing.files

import com.google.common.io.Files
import de.xtendutils.junit.AssertionHelper
import java.io.File
import javax.inject.Inject

import static java.nio.charset.StandardCharsets.UTF_8

class FileTestUtils {

	@Inject protected extension AssertionHelper

	def void assertFileExists(File parent, String child) {
		val file = new File(parent, child)
		file.exists.assertTrue('''Expected file does not exist: «file.absolutePath»''')
	}

	def void assertFileDoesNotExist(File parent, String child) {
		val file = new File(parent, child)
		file.exists.assertFalse('''Unexpected file found: «file.absolutePath»''')
	}

	def String read(File file) {
		return Files.asCharSource(file, UTF_8).read
	}

	def void write(File parent, String child, String contents) {
		val fileToWrite = new File(parent, child)
		Files.createParentDirs(fileToWrite)
		fileToWrite.createNewFile // will not override existing file
		Files.asCharSink(fileToWrite, UTF_8).write(contents)
	}
	

}
