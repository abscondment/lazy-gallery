import android.os.Handler
import android.util.Log

import java.io.File
import java.io.FileOutputStream
import java.io.InputStream
import java.io.IOException
import java.net.MalformedURLException
import java.net.URL
import java.util.concurrent.ConcurrentHashMap
import java.util.concurrent.atomic.AtomicLong

class AsyncDownload
  implements Runnable
  
  def initialize(handler:Handler, url:String, path:String)
    @handler = handler
    @url = url
    @path = path
    
    # Give this download a unique id
    @path_id = Integer.new((@url + @path).hashCode)
    @id = Long.new(AsyncDownload.id_atom.incrementAndGet)

    # Ensure this id is the only one running given url/path.
    existing = Long(AsyncDownload.queue.putIfAbsent(@path_id, @id))
    unless existing.nil? || existing.equals(@id)
      return
    end
    
    LazyGalleryActivity.threadPoolExecutor.execute self
  end

  def self.id_atom
    @id_atom ||= AtomicLong.new
  end
  
  def self.queue
    @queue ||= ConcurrentHashMap.new
  end

  def run:void
    success = true
    file = File.new @path

    # Don't re-fetch an existing file.
    unless file.exists
      request = URL.new(@url)
      Log.v("AsyncDownload", "Fetching " + @url)
      
      begin
        parent = File.new(file.getParent)
        parent.mkdirs unless parent.exists
        tmp = File.createTempFile("AsyncDownload", "" + @url.hashCode, parent)
        
        
        is = InputStream(request.getContent)
        fos = FileOutputStream.new(tmp)
        
        begin
          buffer = byte[4096]
          l = 0
          while (l = is.read(buffer)) != -1
            fos.write(buffer, 0, l)
          end
          fos.flush
          fos.close
          tmp.renameTo file
          is.close

        rescue IOException => e
          # TODO
          Log.e "AsyncDownload", "Read/Write Failed", e
          tmp.delete
          file.delete
          success = false
        ensure
          is.close unless is.nil?
          fos.close unless fos.nil?
        end
      rescue MalformedURLException => e
        # TODO
        Log.e "AsyncDownload", "Fetch Failed", e
        success = false
      rescue IOException => e
        # TODO
        Log.e "AsyncDownload", "Something Failed", e
        success = false
      end
    end

    # I'm done running!
    AsyncDownload.queue.remove(@path_id)
    
    if success
      @handler.sendMessage(@handler.obtainMessage(0, @path))
    else
      @handler.sendEmptyMessage(1)
    end
  end
end
