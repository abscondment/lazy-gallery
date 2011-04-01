import android.app.Activity
import android.os.Bundle
import android.os.Handler
import android.util.Log
import android.view.View
import android.widget.TextView
import android.widget.Toast
import android.widget.Gallery

import java.io.IOException
import java.io.InputStreamReader

import java.util.concurrent.ScheduledThreadPoolExecutor
import java.util.concurrent.ThreadPoolExecutor
import java.util.Map

class LazyGalleryActivity < Activity
  def self.threadPoolExecutor:ThreadPoolExecutor
    @threadPoolExecutor ||= ScheduledThreadPoolExecutor.new(3)
  end
  
  $Override
  def onCreate(state:Bundle)
    super state
    setContentView(R.layout.main)

    gallery = Gallery(findViewById R.id.lazy_gallery)
    gallery.setCallbackDuringFling false
    # gallery.dispatchSetSelected true

    gallery_adapter = LazyGalleryAdapter.new self
    gallery.setAdapter gallery_adapter
    
    caption = TextView(findViewById R.id.lazy_gallery_text)
    caption.setVisibility View.INVISIBLE
    gallery.setOnItemSelectedListener GallerySelectionListener.new(caption)

    this = self
    gallery.setOnItemClickListener do |parent, view, pos, id|
      if view.isSelected
        # Toasty!
        item = Map(gallery_adapter.getItem pos)
        c = String(item.get 'caption') || "Item #{pos} (no caption)"
        Toast.makeText(this, c, Toast.LENGTH_SHORT).show
      end
    end
    
  end

  $Override
  def onResume
    super
    
    # NB: This is a sample application. We'll blow out the image cache each time
    #     the activity resumes to demonstrate lazy-loading. Don't do this in a
    #     production application!
    LazyImageView.purgeDiskCache(self)

    
    # Load up an example JSON file and update the adapter with its contents.
    gallery = Gallery(findViewById R.id.lazy_gallery)
    adapter = LazyGalleryAdapter(gallery.getAdapter)
    begin
      reader = InputStreamReader.new getResources.openRawResource(R.raw.example_json)
      json = StringBuilder.new(1024)
      buf = char[1024]
      len = -1
      while (len = reader.read(buf)) != -1
        json.append(buf, 0, len)
      end
      adapter.update_from_json json.toString
    rescue IOException => e
      Log.e 'LazyGalleryActivity', 'Failed to read example_json.json', e
    end

    # NB: silly hack to trick the gallery into seleting the first item
    gallery.setSelection 1
    runnable = Thread.new do
      gallery.setSelection 0
    end
    Handler.new.postDelayed runnable, 100
  end
end
