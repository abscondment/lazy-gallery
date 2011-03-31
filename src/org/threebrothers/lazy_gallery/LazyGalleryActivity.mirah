import android.app.Activity
import android.os.Bundle

import java.util.concurrent.ScheduledThreadPoolExecutor
import java.util.concurrent.ThreadPoolExecutor

class LazyGalleryActivity < Activity
  
  def self.initialize
    @threadPoolExecutor = ScheduledThreadPoolExecutor.new(3)
  end
  
  def self.threadPoolExecutor:ThreadPoolExecutor
    @threadPoolExecutor
  end
  
  $Override
  def onCreate(state:Bundle)
    super state
    setContentView(R.layout.main)
  end

  $Override
  def onResume
    # NB: This is a sample application. We'll blow out the image cache each time
    #     the activity resumes to demonstrate lazy-loading. Don't do this in a
    #     production application!
    LazyImageView.purgeDiskCache(self)
  end
end