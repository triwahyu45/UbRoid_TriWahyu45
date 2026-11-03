#define _GNU_SOURCE
#include <dlfcn.h>
#include <stdio.h>
#include <string.h>
#include <glib.h>
#include <gtk/gtk.h>

/* Geometry hints interceptor (prevents terminal window gaps) */
void gtk_window_set_geometry_hints(GtkWindow *window, GtkWidget *geometry_widget, GdkGeometry *geometry, GdkWindowHints geom_mask) {
    static void (*real_func)(GtkWindow*, GtkWidget*, GdkGeometry*, GdkWindowHints) = NULL;
    if (!real_func) real_func = dlsym(RTLD_NEXT, "gtk_window_set_geometry_hints");
    if (geometry) {
        geometry->width_inc = 1;
        geometry->height_inc = 1;
        geom_mask &= ~GDK_HINT_RESIZE_INC;
    }
    if (real_func) real_func(window, geometry_widget, geometry, geom_mask);
}

/* Arrow suppression hooks to remove all dropdown triangles from launchers */
static void hide_launcher_arrows(GtkWidget *widget) {
    if (!widget) return;
    const char *name = G_OBJECT_TYPE_NAME(widget);
    if (name && (g_strcmp0(name, "XfceArrowButton") == 0 || strstr(name, "ArrowButton"))) {
        gtk_widget_set_no_show_all(widget, TRUE);
        gtk_widget_hide(widget);
        return;
    }
    if (GTK_IS_CONTAINER(widget)) {
        GList *ch = gtk_container_get_children(GTK_CONTAINER(widget));
        for (GList *l = ch; l; l = l->next) {
            hide_launcher_arrows(GTK_WIDGET(l->data));
        }
        g_list_free(ch);
    }
}

GtkWidget *xfce_arrow_button_new(GtkArrowType arrow_type) {
    static GtkWidget* (*real_func)(GtkArrowType) = NULL;
    if (!real_func) real_func = dlsym(RTLD_NEXT, "xfce_arrow_button_new");
    return real_func ? real_func(arrow_type) : gtk_button_new();
}

void gtk_widget_show(GtkWidget *widget) {
    static void (*real_show)(GtkWidget*) = NULL;
    if (!real_show) real_show = dlsym(RTLD_NEXT, "gtk_widget_show");
    if (widget) {
        const char *name = G_OBJECT_TYPE_NAME(widget);
        if (name && (g_strcmp0(name, "XfceArrowButton") == 0 || strstr(name, "ArrowButton"))) {
            GType launcher_type = g_type_from_name("XfceLauncherPlugin");
            if (launcher_type && gtk_widget_get_ancestor(widget, launcher_type)) {
                gtk_widget_set_no_show_all(widget, TRUE);
                gtk_widget_hide(widget);
                return;
            }
        }
    }
    if (real_show) real_show(widget);
}

void gtk_render_arrow(GtkStyleContext *context, cairo_t *cr, gdouble angle, gdouble x, gdouble y, gdouble size) {
    if (context) {
        GtkWidgetPath *path = gtk_style_context_get_path(context);
        if (path) {
            char *path_str = gtk_widget_path_to_string(path);
            if (path_str) {
                if (strstr(path_str, "arrow") || strstr(path_str, "launcher") || strstr(path_str, "Arrow")) {
                    g_free(path_str);
                    return;
                }
                g_free(path_str);
            }
        }
    }
    static void (*real_render)(GtkStyleContext*, cairo_t*, gdouble, gdouble, gdouble, gdouble) = NULL;
    if (!real_render) real_render = dlsym(RTLD_NEXT, "gtk_render_arrow");
    if (real_render) real_render(context, cr, angle, x, y, size);
}

typedef gint (*get_id_fn)(gpointer);
static get_id_fn p_get_id = NULL;
static get_id_fn p_provider_get_id = NULL;
static int dynamic_spacer_width = 226;


static void dump_widget_tree(GtkWidget *w, int depth, FILE *fp) {
    if (!w) return;
    for (int i = 0; i < depth; i++) fprintf(fp, "  ");
    GtkAllocation a;
    gtk_widget_get_allocation(w, &a);
    fprintf(fp, "%s name=%s vis=%d mapped=%d alloc=[%d,%d %dx%d]\n",
            G_OBJECT_TYPE_NAME(w), gtk_widget_get_name(w),
            gtk_widget_is_visible(w), gtk_widget_get_mapped(w),
            a.x, a.y, a.width, a.height);
    if (GTK_IS_CONTAINER(w)) {
        GList *ch = gtk_container_get_children(GTK_CONTAINER(w));
        for (GList *l = ch; l; l = l->next) {
            dump_widget_tree(GTK_WIDGET(l->data), depth + 1, fp);
        }
        g_list_free(ch);
    }
}
static void check_and_adjust_spacer(GtkWidget *itembar) {
    if (!p_get_id) p_get_id = dlsym(RTLD_DEFAULT, "xfce_panel_plugin_get_unique_id");
    if (!p_provider_get_id) p_provider_get_id = dlsym(RTLD_DEFAULT, "xfce_panel_plugin_provider_get_unique_id");

    GList *children = gtk_container_get_children(GTK_CONTAINER(itembar));
    if (!children) return;

    static int s_dumped = 0;
    FILE *dbg = (!s_dumped) ? fopen("/tmp/children_dump.log", "w") : NULL;

    GtkWidget *spacer = NULL;
    int left_w = 0;
    int right_w = 0;
    int phase = 0; /* 0 = left of sep-2, 1 = middle (sep-2, clock-3, sep-4), 2 = right of sep-4 */

    for (GList *l = children; l; l = l->next) {
        GtkWidget *child = GTK_WIDGET(l->data);
        if (child) {
            gtk_widget_show(child);
            const char *cname = G_OBJECT_TYPE_NAME(child);
            if (cname && strstr(cname, "Launcher")) {
                hide_launcher_arrows(child);
            }
        }

        int uid = -1;
        if (p_provider_get_id) uid = p_provider_get_id(child);
        if (uid <= 0 && p_get_id) uid = p_get_id(child);

        if (dbg) {
            GtkAllocation ca_tmp;
            gtk_widget_get_allocation(child, &ca_tmp);
            fprintf(dbg, "child uid=%d type=%s x=%d w=%d vis=%d\n", uid, G_OBJECT_TYPE_NAME(child), ca_tmp.x, ca_tmp.width, gtk_widget_is_visible(child));
            if (GTK_IS_CONTAINER(child)) {
                GList *ch2 = gtk_container_get_children(GTK_CONTAINER(child));
                for (GList *l2 = ch2; l2; l2 = l2->next) {
                    GtkWidget *w2 = GTK_WIDGET(l2->data);
                    fprintf(dbg, "    sub: type=%s vis=%d\n", G_OBJECT_TYPE_NAME(w2), gtk_widget_is_visible(w2));
                    if (GTK_IS_CONTAINER(w2)) {
                        GList *ch3 = gtk_container_get_children(GTK_CONTAINER(w2));
                        for (GList *l3 = ch3; l3; l3 = l3->next) {
                            GtkWidget *w3 = GTK_WIDGET(l3->data);
                            fprintf(dbg, "        sub3: type=%s vis=%d\n", G_OBJECT_TYPE_NAME(w3), gtk_widget_is_visible(w3));
                        if (GTK_IS_CONTAINER(w3)) {
                            GList *ch4 = gtk_container_get_children(GTK_CONTAINER(w3));
                            for (GList *l4 = ch4; l4; l4 = l4->next) {
                                GtkWidget *w4 = GTK_WIDGET(l4->data);
                                GtkAllocation a4;
                                gtk_widget_get_allocation(w4, &a4);
                                fprintf(dbg, "            sub4: type=%s vis=%d x=%d y=%d w=%d h=%d stype=%d\n", G_OBJECT_TYPE_NAME(w4), gtk_widget_is_visible(w4), a4.x, a4.y, a4.width, a4.height, GTK_IS_IMAGE(w4) ? gtk_image_get_storage_type(GTK_IMAGE(w4)) : -1);
                            }
                            g_list_free(ch4);
                        }
                        }
                        g_list_free(ch3);
                    }
                }
                g_list_free(ch2);
            }
        }

        if (uid == 10) {
            spacer = child;
            continue;
        }
        if (uid == 2) {
            phase = 1;
            continue;
        }
        if (uid == 4) {
            phase = 2;
            continue;
        }

        GtkAllocation ca;
        gtk_widget_get_allocation(child, &ca);
        if (phase == 0) {
            left_w += ca.width;
        } else if (phase == 2) {
            right_w += ca.width;
        }
    }

    if (dbg) {
        fprintf(dbg, "TOTAL: left_w=%d right_w=%d\n", left_w, right_w);
        fclose(dbg);
        s_dumped = 1;
    }
    g_list_free(children);

    if (spacer && right_w > 0) {
        int desired_w = (right_w - left_w);
        if (desired_w <= 0) desired_w = 1;
        if (desired_w > 240) desired_w = 240;

        dynamic_spacer_width = desired_w;

        GtkAllocation sa;
        gtk_widget_get_allocation(spacer, &sa);

        if (sa.width != desired_w) {
            gtk_widget_set_size_request(spacer, desired_w, sa.height > 0 ? sa.height : 36);
            gtk_widget_queue_resize(spacer);
        }
    }
}

void gtk_widget_size_allocate(GtkWidget *widget, GtkAllocation *alloc) {
    static void (*real_alloc)(GtkWidget*, GtkAllocation*) = NULL;
    if (!real_alloc) real_alloc = dlsym(RTLD_NEXT, "gtk_widget_size_allocate");

    if (real_alloc) real_alloc(widget, alloc);

    if (widget) {
        const char *type_name = G_OBJECT_TYPE_NAME(widget);
        if (type_name && strstr(type_name, "PanelItembar")) {
            static int dump_count = 0;
            if (dump_count < 10) {
                char fn[64];
                snprintf(fn, sizeof(fn), "/tmp/itembar_%d.log", dump_count++);
                FILE *fp = fopen(fn, "w");
                if (fp) {
                    dump_widget_tree(widget, 0, fp);
                    fclose(fp);
                }
            }
            check_and_adjust_spacer(widget);
        }
    }
}

void gtk_widget_set_size_request(GtkWidget *widget, int width, int height) {
    static void (*real_set_size)(GtkWidget*, int, int) = NULL;
    if (!real_set_size) real_set_size = dlsym(RTLD_NEXT, "gtk_widget_set_size_request");
    if (!p_get_id) p_get_id = dlsym(RTLD_DEFAULT, "xfce_panel_plugin_get_unique_id");
    if (!p_provider_get_id) p_provider_get_id = dlsym(RTLD_DEFAULT, "xfce_panel_plugin_provider_get_unique_id");

    if (widget) {
        int uid = -1;
        if (p_get_id) uid = p_get_id(widget);
        if (uid <= 0 && p_provider_get_id) uid = p_provider_get_id(widget);

        if (uid == 10) {
            width = dynamic_spacer_width;
        }
    }

    if (real_set_size) real_set_size(widget, width, height);
}

void gtk_window_move(GtkWindow *window, gint x, gint y) {
    static void (*real_move)(GtkWindow*, gint, gint) = NULL;
    if (!real_move) real_move = dlsym(RTLD_NEXT, "gtk_window_move");

    if (window && y > 400) {
        GdkScreen *scr = gtk_window_get_screen(window);
        int screen_h = scr ? gdk_screen_get_height(scr) : 711;

        if (y >= screen_h - 65 && y <= screen_h - 35) {
            /* Lift bottom dock (panel-2) 16px above the bottom edge so it floats
             * above Android's navigation/gesture bar */
            y = screen_h - 47 - 16;

            GtkStyleContext *sc = gtk_widget_get_style_context(GTK_WIDGET(window));
            if (sc) gtk_style_context_add_class(sc, "ubroid-dock");
            if (GTK_IS_BIN(window)) {
                GtkWidget *child = gtk_bin_get_child(GTK_BIN(window));
                if (child) {
                    GtkStyleContext *csc = gtk_widget_get_style_context(child);
                    if (csc) gtk_style_context_add_class(csc, "ubroid-dock");
                }
            }
        }
    }

    if (real_move) real_move(window, x, y);
}
