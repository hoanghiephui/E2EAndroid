package com.e2e.message.ui.adapters;

import android.support.v7.widget.RecyclerView;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.TextView;

import com.e2e.message.R;
import com.e2e.message.data.UserResponse;

import java.util.ArrayList;
import java.util.List;

/**
 * Created by hiep on 9/12/16.
 */
public class ChatRoomsAdapter extends RecyclerView.Adapter<ChatRoomsAdapter.ViewHolder> {
    private List<UserResponse> data = new ArrayList<>();


    public ChatRoomsAdapter(List<UserResponse> data) {
        this.data = data;
    }

    private static OnItemClickListener listener;

    public interface OnItemClickListener {
        void onItemClick(View itemView, int position);
    }

    public void setOnItemClickListener(OnItemClickListener listener) {
        ChatRoomsAdapter.listener = listener;
    }

    @Override
    public ViewHolder onCreateViewHolder(ViewGroup parent, int viewType) {
        return new ViewHolder(LayoutInflater.from(parent.getContext()).inflate(R.layout.item_chat_room, parent, false));
    }

    @Override
    public void onBindViewHolder(ViewHolder holder, final int position) {
        holder.tvUser.setText(data.get(position).getFullName());
        holder.tvUser.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View view) {
                listener.onItemClick(view, position);
            }
        });
    }

    @Override
    public int getItemCount() {
        return data.size();
    }

    public static class ViewHolder extends RecyclerView.ViewHolder {
        private TextView tvUser;

        public ViewHolder(View itemView) {
            super(itemView);
            tvUser = (TextView) itemView.findViewById(R.id.tvUser);
        }
    }


}
