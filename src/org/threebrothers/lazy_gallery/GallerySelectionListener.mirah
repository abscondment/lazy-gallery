import android.view.View
import android.widget.AdapterView
import android.widget.AdapterView.OnItemSelectedListener
import android.widget.TextView
import android.widget.RelativeLayout

import java.util.Map

class GallerySelectionListener
  implements OnItemSelectedListener

  def initialize(textView:TextView)
    @textView = textView
  end
  
  def onItemSelected(parent:AdapterView, view:View, pos:int, id:long)
    unless @textView.nil?
      photo_map = Map(LazyGalleryAdapter(parent.getAdapter).getItem pos)
      if photo_map.containsKey('caption')
        @textView.setText String(photo_map.get('caption'))
        @textView.setVisibility View.VISIBLE
      else
        @textView.setVisibility View.INVISIBLE
      end
    end
    
    view.setSelected true
    
    # Preload children of the Gallery (i.e. those elements that are visible)
    unless parent.nil?
      parent.getChildCount.times do |i|
        v = RelativeLayout(parent.getChildAt(i))
        LazyImageView(v.getChildAt 0).load unless v.nil?
      end
    end
  end

  def onNothingSelected(parent:AdapterView)
    unless @textView.nil?
      @textView.setVisibility View.INVISIBLE
      @textView.setText nil
    end
  end
end
